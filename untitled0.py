#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jun 11 11:41:50 2018

@author: Aymone
"""

import json
import os
import tweepy
from tweepy.streaming import StreamListener
from tweepy import OAuthHandler
from tweepy import Stream

#Variables that contains the user credentials to access Twitter API 
access_token = "918831750545117185-gPnuR2dg4cqBQrt92cgVhefEnjosmz5"
access_token_secret = "a3FqtsmGFoBHhTNWaEhXSgVvUWCL5ZSLjSnvNgqGOfv2Z"
consumer_key = "NHjXWPfMHWUHkFqcjPkPASBgV"
consumer_secret = "wOdeIO703WiRa2XQ74x0KGXM4PoEXQPeUkpGtLm9tltrEMEDQF"

#Basic listener that retrieves tweets
class TweetsListener(StreamListener):
    
    def on_data(self, Tweets):
        #dumping data into a JSON file
        with open('twitter_data.json', 'w') as t:
            json.dump(Tweets, t)
        return True

    def on_error(self, status):
        print(status)
        
    def on_timeout(self):
        print >> sys.stderr, 'Timeout...waiting for connection to proceed...'
        return True # Don't kill the stream
 

if __name__ == '__main__':

    #This handles Twitter authetification and the connection to Twitter Streaming API
    TweetsListener = TweetsListener()
    auth = OAuthHandler(consumer_key, consumer_secret)
    auth.set_access_token(access_token, access_token_secret)
    
    stream = Stream(auth, TweetsListener)

    #This line filter Twitter Streams to capture data. 
    # many options: could capture a random sample or capture by keyword
    # up to 400 keywords can be used. For max data stream it is good to capture 
    #by most popular words used on twitter such as 'the', 
    # http://techland.time.com/2009/06/08/the-500-most-frequently-used-words-on-twitter/
    # example: stream.filter(track=['the', 'and'])
    #stream.sample()
    stream.filter(track=['cyber', 'cybersecuirty', 'smb', 'small business'])
   