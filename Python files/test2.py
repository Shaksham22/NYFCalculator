raw="""Eat In
CASH
DEBIT
VISA
MASTERCARD
AMEX
GIVEX
Rounded
Rounded
Sales
- Tax
Net
Delivery
DOORDASH
UBER EATS
SKIP DISHES
Sales
- Tax
Net
HST 5%
HST 8%
Total Taxes
Gross Sales
- Tax
Net
$821.95
$1,899.11
$353.15
$218.01
$5.41
$28.29
($0.35)
$0.45
$3,326.02
$2,943.69
$2,943.69
$181.96
$158.13
$245.95
$586.04
$518.58
$518.58
$172.87
$276.92
$449.79
$3,912.06
$3,462.27
$3,462.27"""

raw=raw.lower()


raw2="""4
Clearview POS Sales By Order Type Report
Intercity Mall, Thunder Bay, Ont.
Requested by DHRUVI
Run on 05-24-2024 At 20:56:43
During Shift: 1
For the day of 05-24-2024
# of Checks
248
Eat In
CASH
DEBIT
VISA
MASTERCARD
AMEX
GIVEX
Rounded
Rounded
Sales
- Tax
Net
$881.90
$1,711.19
$323.32
$155.18
$15.53
($23.91)
($0.45)
$0.39
$3,063.15
$2,711.18
$2,711.18
Delivery
UBER EATS
SKIP DISHES
Sales
- Tax
Net
$191.19
$385.00
$576.19
$509.86
$509.86
HST 5%
HST 8%
$161.05
$257.25
Total Taxes
Gross Sales
- Tax
Net
$418.30
$3,639.34
$3,221.04
$3,221.04"""

raw3="""4
Clearview POS Sales By Order Type Report
Intercity Mall, Thunder Bay, Ont.
Requested by DHRUVI
Run on 05-24-2024 At 20:56:43
During Shift: 1
For the day of 05-24-2024
# of Checks
248
Eat In
CASH
DEBIT
VISA
MASTERCARD
AMEX
GIVEX
Rounded
Rounded
Sales
- Tax
Net
$881.90
$1,711.19
$323.32
$155.18
$15.53
($23.91)
($0.45)
$0.39
$3,063.15
$2,711.18
$2,711.18"""


raw2=raw2.lower()



def function0(raw):
    raw=raw.lower()
    raw=raw[raw.index("eat in"):]
    l1=raw.split("\n")
    for i,a in enumerate(l1):
        if(a[0]=="$"):
            l1[i]=float(a[1:].replace(",",""))
        if(a[0]=="("and a[1]=="$"):
            l1[i]=-float(a[2:-1].replace(",",""))
    blocks=[]
    n=0
    internaln=None
    flag=False
    for i,a in enumerate(l1):
##        print(type(a),flag)
        if(type(a)==float and flag==False):
            internaln=i
            flag=True
        if(type(a)==str and flag==True and i!=0):
            blocks.append([l1[n:internaln],l1[internaln:i]])
            n=i
            flag=False
    blocks.append([l1[n:internaln],l1[internaln:]])
##    for i in blocks:
##        print("strlist=",i[0])
##        print("vallist=",i[1])
    finalhashmap = {}
    finaldisplayorder={}
    for block in blocks:
        curhashmap,displayorder = function1(block)
        
        for key, inner_dict in curhashmap.items():
            if key in finalhashmap:
                # Merge the inner dictionaries
                finalhashmap[key].update(inner_dict)
                finaldisplayorder[key]=finaldisplayorder[key]+displayorder[key]
            else:
                # Add new top-level key
                finalhashmap[key] = inner_dict
                finaldisplayorder[key]=displayorder[key]
    print(finaldisplayorder)
    return finalhashmap,finaldisplayorder

def function1(l1):
    keywords1=["eat in","delivery","take out"]
    keywords2=["hst 5%","total taxes"]
    words=l1[0]
    numbers=l1[1]
    ct=0
    d={}
    cur=None
    displayorder={}
    for i,a in enumerate(words):
        if(a in keywords1):
            d[a]=dict()
            displayorder[a]=[]
            cur=a
            ct-=1
            continue
        if(a in keywords2 and "end" not in d):
            d["end"]=dict()
            displayorder["end"]=[]
            cur="end"
        d[cur][a]=numbers[i+ct]
        displayorder[cur].append(a)
    return(d,displayorder)
##print(function1(raw))
##d=function1(raw)
##print(function1(raw3))
##d2=function1(raw3)


##    
##print(function0(raw2))
d3,order=function0(raw2)

##for i in d3:
##    print(i,":",d3[i])

d3,order=function0(raw)
##for i in d3:
##    print(i,":",d3[i])
