#!/usr/bin/python3
# -*- coding: utf-8 -*-

# pip3 install selenium
# apt-get install chromium-driver

from atlassian import Confluence
from selenium.webdriver import Chrome, ChromeOptions
from selenium.webdriver.common.by import By
import time, os, sys

URL='http://confluencehost'
USERNAME='username'
PASSWORD='password'

def export_all_spces(spaces):
    #  禁止弹出窗口，设置默认下载路径
    prefs = {'profile.default_content_settings.popups':0, 'download.default_directory':os.getcwd()}

    opt = ChromeOptions()            # 创建Chrome参数对象
    opt.headless = True              # 把Chrome设置成可视化无界面模式，windows/Linux 皆可
    opt.add_experimental_option('prefs', prefs)
    driver = Chrome(options=opt)     # 创建Chrome无界面对象

    driver.get(URL)
    driver.find_element(By.ID, "os_username").clear()
    driver.find_element(By.ID, "os_username").send_keys(USERNAME)

    driver.find_element(By.ID, "os_password").clear()
    driver.find_element(By.ID, "os_password").send_keys(PASSWORD)
    driver.find_element(By.ID, "loginButton").click()

    for space in spaces:
        driver.get(URL + '/spaces/flyingpdf/flyingpdf.action?key=' + space['key'])
        driver.find_element(By.XPATH, '//*[@id="space-tools-body"]/div/form/div[1]/fieldset[1]/div[1]/label').click() # 选择普通导出
        driver.find_element(By.XPATH, '//*[@id="space-tools-body"]/div/form/div[1]/fieldset[2]/div/label').click()   # 包含页码


        driver.find_element(By.XPATH, '//*[@id="space-tools-body"]/div/form/div[2]/div/input').click()
        print("wait space " + space['name'] + ' export done')
        while True:
            percent = driver.find_elements(By.ID, "percentComplete")
            if percent != None:
                print("percent = " + percent[0].text)
                if int(percent[0].text) >= 100:
                    break
            time.sleep(2)

        download_btn = driver.find_element(By.CLASS_NAME, 'space-export-download-path')
        link = download_btn.get_attribute("href")
        filename = link.split('/')[-1]
        print("start download " + filename)
        download_btn.click()

        # 等待文件下载完成
        while filename not in os.listdir():
            print("wait download complete...")
            time.sleep(1)

        new_filename = filename.replace(space['key'], space['name'].strip())
        try:
            os.rename(filename, new_filename)
        except Exception as e:
            print(e)
    driver.close()
    return 0

def main(argv):
    confluence = Confluence(url=URL, username=USERNAME, password=PASSWORD)
    spaces = confluence.get_all_spaces(start=0, limit=500, expand=None)
    spaces = spaces['results']
    export_all_spces(spaces)
    return 0

if __name__ == "__main__":
    main(sys.argv)
