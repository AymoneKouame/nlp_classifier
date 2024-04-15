#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jun 11 12:12:47 2018

@author: Aymone
"""

from twython import Twython

access_token = "918831750545117185-gPnuR2dg4cqBQrt92cgVhefEnjosmz5"
access_token_secret = "a3FqtsmGFoBHhTNWaEhXSgVvUWCL5ZSLjSnvNgqGOfv2Z"
consumer_key = "NHjXWPfMHWUHkFqcjPkPASBgV"
consumer_secret = "wOdeIO703WiRa2XQ74x0KGXM4PoEXQPeUkpGtLm9tltrEMEDQF"

t = Twython(app_key=consumer_key, 
            app_secret=consumer_secret, 
            oauth_token=access_token, 
            oauth_token_secret=access_token_secret)

search = t.search(q='#CyberSecurity, #smb, #sme',   # hashtag
                  count=200, result_type =  'popular')
                  #, lang = "eng", result_type =  "popular" )


tweets = search['statuses']

for tweet in tweets:
    print (tweet['id_str'], '\n', tweet['text'], '\n\n\n')