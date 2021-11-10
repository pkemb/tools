#!/usr/bin/python3
# -*- coding: utf-8 -*-

"""
1. get_all_spaces() 获取所有空间的key
2. get_home_page_of_space() 获取指定空间的homepage id
3. get_page_child_by_type() 获取指定页面的一级子页面
4. 递归获取页面转化为BytesIO对象，追加到PdfFileMerger对象
5. PdfFileMerger写入到文件，使用space name作为文件名。
"""

import sys
from atlassian import Confluence
from PyPDF2 import PdfFileMerger
from io import BytesIO

URL='http://confluencehost'
USERNAME='username'
PASSWORD='password'

confluence = Confluence(url=URL, username=USERNAME, password=PASSWORD)

# 从root页面递归导出所有页面
def export_pages(merger, pageid):
    pagepdf = confluence.get_page_as_pdf(pageid)
    merger.append(BytesIO(pagepdf))

    childpages = confluence.get_page_child_by_type(pageid)
    for childpage in childpages:
        export_pages(merger, childpage["id"])
    return 0

def export_space(key, name):
    homepage = confluence.get_home_page_of_space(key)
    merger = PdfFileMerger()
    export_pages(merger, homepage["id"])
    merger.write(name + ".pdf")
    merger.close()
    return 0

def main(argv):

    spaces = confluence.get_all_spaces(start=0, limit=500, expand=None)
    spaces = spaces['results']
    for space in spaces:
        export_space(space["key"], space["name"])
        print("export space " + space["name"] + " done")

    return 0

if __name__ == "__main__":
    main(sys.argv)