# coding: utf-8

# In[1]:

using Gadfly
using DataFrames
using Dates
using RDatasets


# In[2]:

plot(x=rand(10), y=rand(10), Geom.point, Geom.line)


# In[3]:

plot(x=0.5:9.5, y=rand(10), Geom.bar)


# In[5]:

plot(dataset("datasets", "iris"), x="SepalLength", y="SepalWidth", Geom.point)


# In[6]:

barplot=plot(x=0.5:9.5, y=rand(10), Geom.bar)
draw(PDF("myplot.pdf", 4inch, 3inch), barplot)
draw(PNG("myplot.png", 4inch, 3inch), barplot)


# In[7]:

replace("mwahaha", "ha", "3")


# In[8]:

contains("mwahaha", ".")


# In[12]:

DateTime("Thu Oct 16 11:17:03 2014", "e uuu dd HH:MM:SS yyyy")


# In[9]:

split("hello there", " ")[1]


# In[10]:

Second(int(Millisecond(11000))/1000)


# In[1]:

zip([1,2,3], [4,5,6])


# In[8]:

[4,5,6]+[1,2,3]


# In[18]:

Pkg.installed()
