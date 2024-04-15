#input is csv file 2 columns - column on left are features and column on right are links. One link per row
import os
import pandas as pd
import requests
from bs4 import BeautifulSoup
from bs4.element import Comment

article = pd.read_excel("RiskFactors_trainingdata.xlsx")

def spot_visible(element):
    if element.parent.name in ['style', 'script', 'head', 'title', 'meta', '[document]']:
        return False
    if isinstance(element, Comment):
        return False
    return True


for l in article:
    for rowid in range(len(article)):
        try:
            n = rowid
            link = str(article.iloc[n,1])
            datapage = requests.get(link)
            datasoup = BeautifulSoup(datapage.text, "html.parser")
            text = datasoup.find_all(text=True)
            visible_texts = filter(spot_visible, text)

            fname = str(article.iloc[n,0])+" "+str(n)+".txt"
            filename = os.path.join("RiskFactors_trainingdata", fname)
            with open(filename, "a") as d:
                d.write(str(visible_texts))
              
        except BaseException:
            n= n+1
            link = str(article.iloc[n, 1])
            datapage = requests.get(link)
            datasoup = BeautifulSoup(datapage.text, "html.parser")
            text = datasoup.find_all(text=True)
            visible_texts = filter(spot_visible, text)

            fname = str(Train.iloc[n,0])+" "+str(n)+".txt"
            filename = os.path.join("RiskFactors_trainingdata", fname)
            with open(filename, "a") as d:
                d.write(str(visible_texts))

        except requests.exceptions.SSLError:
            n= n+1
            link = str(Train.iloc[n, 1])
            datapage = requests.get(link)
            datasoup = BeautifulSoup(datapage.text, "html.parser")
            text = datasoup.find_all(text=True)
            visible_texts = filter(spot_visible, text)

            fname = str(Train.iloc[n,0])+" "+str(n)+".txt"
            filename = os.path.join("RiskFactors_trainingdata", fname)
            with open(filename, "a") as d:
                d.write(str(visible_texts))