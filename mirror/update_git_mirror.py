#!/usr/bin/env python3

# 参考：

# 1. 线程池与进程池，https://zhuanlan.zhihu.com/p/65638744
# 2. 执行shell命令并获取输出，https://zhuanlan.zhihu.com/p/121543384
#                         https://docs.python.org/3/library/subprocess.html
# 3. python 遍历 https://blog.csdn.net/qq_39839807/article/details/104070761
# 4. python 日志 https://zhuanlan.zhihu.com/p/166671955
# 5. 内置异常 https://docs.python.org/zh-cn/3/library/exceptions.html
# 6. 环境变量 https://blog.csdn.net/zzq900503/article/details/84977468
# 7. url解析 https://blog.csdn.net/LeonTom/article/details/89520981
#           https://docs.python.org/3/library/urllib.parse.html

from concurrent.futures import ThreadPoolExecutor, as_completed, wait
import os
import sys
from subprocess import Popen, PIPE, STDOUT
import logging as log
import re
from urllib.parse import urlparse
import argparse

GIT_MIRROR_DIR = "/mirror/git/mirror"
BLACK_LIST_REPO="/mirror/git/black_list_repo.txt"
RETRY_COUNT    = 10

log.basicConfig(level=log.INFO, format="[%(asctime)s - %(levelname)s - %(lineno)04d] %(message)s")

def is_git_repo(path):
    head = os.path.join(path, "HEAD")
    return os.path.isfile(head)

def check_repo_url(url):
    if re.match(r'^https?://([a-zA-Z0-9._-]*/)+[a-zA-Z0-9._-]*', url):
        return True
    return False

def fetch_repo(path):
    if not is_git_repo(path):
        return -1

    cmd = f"git fetch --progress --auto-gc --all"
    retry = RETRY_COUNT
    while retry > 0:
        log.info(f"start fetch repo {path}")
        proc = Popen(cmd,
                stdout=PIPE,
                stderr=STDOUT,
                shell=True,
                cwd=path,
                encoding='utf-8')
        # wait subprocess exit and read out & err
        # outs, errs = proc.communicate()
        # realtime read output
        for line in proc.stdout:
            log.info(f'[{path}] {line[0:-1]}')
        returncode = proc.wait()
        if returncode == 0:
            log.info(f'fetch {path} success')
            return 0

        retry -= 1
        log.info(f"fetch {path} fail, retry {retry}")

    log.error(f"fetch {path} {RETRY_COUNT} times still fail")
    return -1

def clone_repo(url):
    if url.endswith('.git'):
        url=url[0:-4]
    res = urlparse(url)
    if res.scheme not in ['http', 'https']:
        log.error(f"not support scheme {res.scheme}, url: {url}")
        raise ValueError

    full_path = os.path.join(GIT_MIRROR_DIR, res.hostname, res.path.lstrip('/'))
    if os.path.isdir(full_path):
        return fetch_repo(full_path)

    log.info(f'clone repo {url} to {full_path}')
    repo_name = os.path.basename(full_path)
    repo_path = os.path.dirname(full_path)
    if not os.path.exists(repo_path):
        os.makedirs(repo_path)

    retry = RETRY_COUNT
    cmd = f'git clone --progress --mirror \"{url}\" \"{repo_name}\"'
    while retry > 0:
        proc = Popen(cmd, stdout=PIPE, stderr=STDOUT, shell=True,
                     cwd=repo_path, encoding='utf-8')
        # outs, errs = proc.communicate()
        for line in proc.stdout:
            log.info(f'[{url}] {line[0:-1]}')
        returncode = proc.wait()
        if returncode == 0:
            with open(os.path.join(full_path, 'description'), 'w') as f:
                f.write(f'mirror {url}')
            log.info(f"git clone \"{url}\" success")
            return 0

        retry -= 1
        log.info(f'clone {url} fail, retry {retry}')

    log.error(f"clone {url} {RETRY_COUNT} times still fail")
    return -1


def find_git_repo(root):
    """
    找出指定目录下的所有git仓库
    """
    repos = list()
    if not os.path.isdir(root):
        return repos


    if is_git_repo(root):
        repos.append(root)
        # 假设git仓库不会包含其他git仓库，所以这里直接返回
        return repos


    for item in os.scandir(root):
        if is_git_repo(item.path):
            repos.append(item.path)
        # 假设git仓库不会包含其他git仓库，所以这里是elif，
        elif item.is_dir():
            repos += find_git_repo(item.path)
    return repos

def thread_done_callback(future):
    exception = future.exception()
    if exception:
        log.exception("worker return exception: {}".format(exception))

def submit_work(handler, args, max_workers):
    executor = ThreadPoolExecutor(max_workers=max_workers)
    tasks = list()

    for arg in args:
        future = executor.submit(handler, **arg)
        future.add_done_callback(thread_done_callback)
        tasks.append(future)

    total = len(args)
    done = 0
    fail = 0
    for future in as_completed(tasks):
        done += 1
        if future.result() != 0:
            fail += 1
        log.info(f'process: {done/total*100:.2f}% ({done}/{total}), success: {done-fail}, fail: {fail}')
    return fail

def update_all_mirror_repo(max_workers, blacklist = list()):
    repos = find_git_repo(GIT_MIRROR_DIR)

    for black in blacklist:
        if black in repos:
            repos.remove(black)
            log.info(f'skip {black}')

    args = [{'path':p} for p in repos]
    return submit_work(fetch_repo, args, max_workers)

def clone_repos(urls, max_workers):
    args = [{'url': url} for url in urls]
    if (max_workers > len(urls)):
        max_workers = len(urls)
    return submit_work(clone_repo, args, max_workers)

def main():
    parser = argparse.ArgumentParser()

    parser.add_argument('--proxy', required=False, default=None)
    parser.add_argument('--url',  required=False, default=None, nargs='+', action='append')
    parser.add_argument('--thread', required=False, default=20, type=int)
    parser.add_argument('--retry', required=False, default=10, type=int)
    args = parser.parse_args()

    RETRY_COUNT = args.retry
    if args.proxy and args.proxy != '':
        log.info(f'set proxy {args.proxy}')
        os.environ['http_proxy']  = args.proxy
        os.environ['https_proxy'] = args.proxy

    if args.url:
        urls = sum(args.url, [])
    else:
        urls = list()

    while '' in urls:
        urls.remove('')

    blacklist = list()
    if 'http_proxy' not in os.environ:
        # 没有开代理，才需要黑名单
        with open(BLACK_LIST_REPO, 'r') as f:
            blacklist = f.read().splitlines()

    if len(urls) > 0:
        ret = clone_repos(urls, args.thread)
    else:
        ret = update_all_mirror_repo(args.thread, blacklist = blacklist)
    return ret

if __name__ == "__main__":
    sys.exit(main())
