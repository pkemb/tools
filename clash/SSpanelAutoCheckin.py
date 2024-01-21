
from requests import Session
import logging as log
import sys
import argparse

class SSPanel():
    agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36"
    login_response = None

    def __init__(self, url, account, password) -> None:
        self.url = url
        self.account = account
        self.password = password
        self.session = Session()

        self.session.headers.update({
            "User-Agent": self.agent,
        })

        self.login()

    def login(self):
        if self.login_response:
            return self.login_response

        params = {
            "email": self.account,
            "passwd": self.password,
            "code": ""
        }

        r = self.session.post(self.url + "/auth/login", params=params)
        msg = r.json()['msg']
        if msg != '登录成功':
            raise Exception(r.json()['msg'])
        log.info(f'login msg: {msg}')
        self.login_response = r
        return r

    def checkin(self):
        r = self.session.post(self.url + "/user/checkin")
        msg = r.json()['msg']
        log.info(f'checkin msg: {msg}')
        return r

def main():
    parser = argparse.ArgumentParser()

    parser.add_argument('--host', required=True, help='机场URL')
    parser.add_argument('--account', required=True, help='账号')
    parser.add_argument('--password', required=True, help='密码')
    args = parser.parse_args()

    client = SSPanel(args.host, args.account, args.password)
    client.checkin()
    return 0

if __name__ == "__main__":
    format = "[%(asctime)s - %(levelname)s - %(module)s - %(lineno)04d] %(message)s"
    log.basicConfig(level=log.INFO, format=format)
    log.getLogger('connectionpool').level = log.WARNING
    sys.exit(main())
