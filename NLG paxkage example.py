#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Jun 10 23:08:15 2018

@author: Aymone
"""


import pandas as pd # data processing, çCSV file I/O (e.g. pd.read_csv)
import markovify as mk #Markov Chain Generator

samplearticle = open("cyberhygiene.txt","r") 
samplearticle = samplearticle.read()

samplearticle2 = pd.read_excel("example.xlsx")

#samplearticle.read()

textmodel = mk.NewlineText(str(samplearticle), state_size = 2)

textmodel2 = mk.NewlineText(str(samplearticle2), state_size = 2)


for i in range(10):
    print(textmodel.make_sentence())

for i in range(10):
    print(textmodel2.make_sentence())
    
