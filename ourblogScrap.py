#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jun 11 13:12:49 2018

@author: Aymone
"""

#input is csv file 2 columns - column on left are features and column on right are links. One link per row
import os
import pandas as pd
import requests
from bs4 import BeautifulSoup
from bs4.element import Comment



def spot_visible(element):
    if element.parent.name in ['style', 'script', 'head', 'title', 'meta', '[document]']:
        return False
    if isinstance(element, Comment):
        return False
    return True


for l in data:
    for rowid in range(len(data)):
        try:
          n = rowid
          link = str(data.iloc[n])
          datapage = requests.get(link)
          datasoup = BeautifulSoup(datapage.text, "html.parser")
          text = datasoup.find_all(text=True)
          visible_texts = filter(spot_visible, text)

          fname = "ourblogs.txt"
          with open(fname, "a") as d:
              d.write(str(visible_texts))

        except requests.exceptions.SSLError:
            n= n+1
            link = str(data.iloc[n])
            datapage = requests.get(link)
            datasoup = BeautifulSoup(datapage.text, "html.parser")
            text = datasoup.find_all(text=True)
            visible_texts = filter(spot_visible, text)

            fname = "ourblogs.txt"
            with open(fname, "a") as d:
                d.write(str(visible_texts))