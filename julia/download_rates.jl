# coding: utf-8

# In[1]:

using Gadfly
using DataFrames
using Dates


# In[2]:

copy_df = readtable("copytimes.txt", separator='\t')


# In[3]:

function makedate(dstr)
    dstr = replace(dstr, "PDT ", "")
    DateTime(dstr, "e uuu dd HH:MM:SS yyyy")
end
makedate("Thu Oct 16 11:29:48 PDT 2014")


# In[4]:

copy_df[:tstart] = map(makedate, copy_df[:tstart])
copy_df[:tend] = map(makedate, copy_df[:tend])
copy_df[:duration] = copy_df[:tend] - copy_df[:tstart]
copy_df[:duration] = map((x -> Second(int(x)/1000)), copy_df[:duration])
copy_df


# In[5]:

function sizebytes(sizestr)
    # suffix lookup table
    suffixes = ["G" => 1024*1024, "K" => 1, "M" => 1024, "T" => 1024*1024*1024]
    # get rid of comment after the end
    sizestr = split(sizestr, " ")[1]
    # get the last character of the string
    suffnum = suffixes[string(sizestr[end])]
    num = int(sizestr[1:end-1])
    suffnum*num
end
sizebytes("3M")


# In[6]:

copy_df[:size] = map(sizebytes, copy_df[:size])
copy_df


# In[7]:

copy_df[:rate_kps] = copy_df[:size] ./ map(int, copy_df[:duration])
copy_df


# In[8]:

t = Theme(bar_spacing=0.8inch)
s = Scale.y_continuous(minvalue=0, maxvalue=6*10^4)
plot(copy_df, s, t,
        x=:name, y=:rate_kps,
        Geom.bar, color=:dataset,
        Guide.ylabel("Rate (KB/s)"),
        Guide.xlabel("Test"),
        Guide.title("Download Rates by Method"))


# In[9]:

by(copy_df, :dataset, df -> sum(int(df[:duration])))


# In[10]:

by(copy_df, :tstart, df -> sum(df[:rate_kps]))


# In[11]:

name_hdfs(x) = contains(x, utf8("hdfs2"))


# In[12]:

@vectorize_1arg UTF8String name_hdfs


# In[13]:

copy_small = copy_df[name_hdfs(copy_df[:name]) .== false, :]


# In[14]:

t = Theme(bar_spacing=1.1inch)
s = Scale.y_continuous(minvalue=0, maxvalue=6*10^4)
plot(copy_small, s, t,
        x=:name, y=:rate_kps,
        Geom.bar, color=:dataset,
        Guide.ylabel("Rate (KB/s)"),
        Guide.xlabel("Test"),
        Guide.title("Download Rates by Method"))
