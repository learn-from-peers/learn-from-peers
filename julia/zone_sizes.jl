# coding: utf-8

# In[1]:

# import the right things
using Gadfly
using DataFrames
using Dates


# In[2]:

# load the data
sizes = readtable("allcounts.txt", separator=' ', header=false, names=[:tld, :date, :size])
# Change date strings into dates
dates = map(x -> Date(x, "yyyy-mm-dd"), sizes[:date])
sizes[:date] = convert(DataArray{Date, 1}, dates)
println(eltypes(sizes))
sizes[1:3, :]


# In[3]:

# Do some filtering!
# in particular I don't yet want old data because there's not enough for it to be meaningful
d = Date(2014, 1, 1)
sizes = sizes[Bool[d < x for x in sizes[:date]], :]
# also we want to remove duplicates!
println(size(sizes, 1))
sizes = by(sizes, [:tld, :date], df -> maximum(df[:size]))
rename!(sizes, :x1, :size)
size(sizes, 1)


# In[4]:

# go through and sub in estimated data for missing dates (to smooth the graph)
lasttld = ""
lastdate = 0
lastsize = 0
filledsizes = deepcopy(sizes)
println(eltypes(filledsizes))
for line in eachrow(sizes)
    if line[:tld] != lasttld
        lasttld = line[:tld]
        lastdate = line[:date]
        lastsize = line[:size]
        continue
    end
    if lasttld == line[:tld] && lastdate == line[:date]
        println("already wrote record for $(line)")
    end
    datediff = int(line[:date] - lastdate)
    if datediff > 1
        step = (line[:size] - lastsize) / datediff # float
        tlds = fill(line[:tld], datediff-1)
        dates = map(x -> Day(x) + lastdate, 1:(datediff-1))
        counts = map(x -> int(step*x + lastsize), 1:(datediff-1))
        newdata = DataFrame(tld=tlds, date=dates, size=counts)
        append!(filledsizes, newdata)
    end
    lastdate = line[:date]
    lastsize = line[:size]
end
sizes = filledsizes
sizes[1:3, :]


# In[5]:

# figure out which ones are old zones
OLD_ZONES=["aero", "arpa", "biz", "com", "info", "net", "org", "us", "xxx"]
sizes[:oldzone] = map(x -> in(x, OLD_ZONES), sizes[:tld])
sizes[1:3, :]


# In[6]:

# group by old zone and date and sum subgroups
oldbytime = by(sizes, [:oldzone, :date], df -> sum(df[:size]))
rename!(oldbytime, :x1, :num)
oldbytime[1:3, :]


# In[7]:

plot(oldbytime,
        x=:date, y=:num,
        Geom.line, color=:oldzone,
        Guide.ylabel("Domains"),
        Guide.xlabel("Date"),
        Guide.title("Old vs New TLDs by Date"))
