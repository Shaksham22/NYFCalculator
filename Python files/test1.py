




raw="""Eat In
CASH $821.95
DEBIT $1,899.11
VISA $353.15
MASTERCARD $218.01
AMEX $5.41
GIVEX $28.29
Rounded ($0.35)
Rounded $0.45
Sales $3,326.02
- Tax $2,943.69
Net $2,943.69
Delivery
DOORDASH $181.96
UBER EATS $158.13
SKIP DISHES $245.95
Sales $586.04
- Tax $518.58
Net $518.58
HST 5% $172.87
HST 8% $276.92
Total Taxes $449.79
Gross Sales $3,912.06
- Tax $3,462.27
Net $3,462.27"""





def function0(raw):
    import re
    raw = raw.lower()
    blocks = dict()
    orders = dict()

    try:
        raw = raw[raw.index("eat in"):]
    except ValueError:
        pass

    raw = raw.split("\n")
    cur = None
    keywords1 = ["eat in", "delivery", "take out"]

    for i in raw:
        i = i.strip()
        if i in keywords1:
            cur = i
            blocks[i] = dict()
            orders[i] = []
            continue

        if "hst 5%" in i:
            cur = "end"
            blocks[cur] = dict()
            orders[cur] = []
        print(i)
        label=None
        amount=None
        temp=None
        if "(" in i and ")" in i:
            temp=i.replace("(","")
            temp=temp.replace(")","")
            temp=temp.split("$")
            temp[0]=temp[0].rstrip()
            temp[1]=-float(temp[1].replace(",",""))
        else:
            temp=i.split("$")
            temp[0]=temp[0].rstrip()
            temp[1]=float(temp[1].replace(",",""))
        label=temp[0]
        amount=temp[1]
            

        if label == "rounded" and "rounded" in blocks[cur]:
            label = "rounded2"

        blocks[cur][label] = amount
        orders[cur].append(label)

    return blocks, orders

print(function0(raw))
a,b=function0(raw)
