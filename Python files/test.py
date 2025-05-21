def generate_denomination_lines(individual_denomination_counts,
                           bundle_denomination_counts):
    receipt_lines = []
    bs=" "
    l=['100.00', '50.00', '20.00', '10.00', '5.00', '2.00', '1.00', '0.25', '0.10', '0.05']
    b=['1.00', '0.25', '0.10', '0.05']
    bval={1:25,0.25:10,0.10:5,0.05:2}
    totalval=0
    m = max(len(max(l, key=len)), len(max(b, key=len)))
    mct = max(max(len(str(v)) for v in individual_denomination_counts.values()),
    max(len(str(v)) for v in bundle_denomination_counts.values()))
    print(m,mct)
    for i in l:
        denom = float(i)
        key = int(denom) if denom >= 1 else denom
        val=0
        if(denom in individual_denomination_counts):
            val = str(individual_denomination_counts[key])
        else:
            continue
        total = f"{float(val) * denom:.2f}"
        totalval+=float(total)

        # Line formatting: "$100.00  x  2   =  $200.00"
        line = (
            " $" + i +
            bs * (m - len(i) + 2) + "x" +
            bs * 3 + val + bs +
            bs * (2 + mct - len(val)) + "=" +
            bs * 2 + "$" + total)
        receipt_lines.append(line)


        


    for i in b:
        denom = float(i)
        key = int(denom) if denom >= 1 else denom
        val=0
        if(denom in bundle_denomination_counts):
            val = str(bundle_denomination_counts[key])
        else:
            continue
        print(f"{float(val) * bval[denom]:.2f}")
        total = f"{float(val) * bval[denom]:.2f}"
        totalval+=float(total)
        line = (
            " $" + i +
            bs * (m - len(i) + 2) + "x" +
            bs * 2 + "("+val+")" +
            bs * (2 + mct - len(val)) + "=" +
            bs * 2 + "$" + total)
        receipt_lines.append(line)

    
    longestline=(max(receipt_lines, key=len))
    resline = " Total" + (len(longestline.split("=")[0]) -6) * bs + "=" + bs * 2 + "$" + f"{totalval:.2f}"
    receipt_lines.append("-"*(len(longestline)+2))
    receipt_lines.append(resline)
    return(receipt_lines)
    


def generate_receipt_lines(employee_name, current_date, table_title,
                           individual_denomination_counts,
                           bundle_denomination_counts):
    

    receipt_lines =generate_denomination_lines(individual_denomination_counts,
                           bundle_denomination_counts)

    print(len( receipt_lines))
    return(receipt_lines)


# Example usage
if __name__ == "__main__":
    lines = generate_receipt_lines(
        employee_name="John Doe",
        current_date="May 14 2025",
        table_title="Denomination Summary",
        individual_denomination_counts={100: 2, 50: 4, 10: 1,0.10:5},
        bundle_denomination_counts={0.25: 3}
    )

    for line in lines:
        print(line)
