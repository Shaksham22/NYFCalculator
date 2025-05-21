def get_denominations():
    denominations = {
        100: 0,
        50: 0,
        20: 0,
        10: 0,
        5: 0,
        2: 0,
        1: 0,
        0.25: 0,
        0.10: 0,
        0.05: 0
    }
    currency = sorted(denominations.keys(), reverse=True)
    
    for denom in currency:
        count = int(input(f"Enter the number of {denom} dollar notes/coins available: "))
        denominations[denom] = count
    
    return denominations

def allocate_denominations(amount, denominations):
    allocated = {denom: 0 for denom in denominations}
    for denom in sorted(denominations.keys(), reverse=True):
        while denominations[denom] > 0 and amount >= denom:
            denominations[denom] -= 1
            allocated[denom] += 1
            amount -= denom
            amount = round(amount, 2)  # To avoid floating point precision issues
            print(f"Remaining amount to allocate: {amount}")
    
    return allocated, amount

def calculate_remaining(denominations):
    remaining = sum(denom * count for denom, count in denominations.items())
    return round(remaining, 2)

def main():
    # Get inputs
    total_sales = float(input("Enter total sales: "))
    mid_day_sales = float(input("Enter mid-day sales: "))
    denominations = get_denominations()
    
    # Calculate end day sales and x
    x = total_sales - mid_day_sales
    x = round(x, 2)
    print(f"\nEnd day sales (x): {x}")
    
    # Allocate denominations to x
    allocated_x, remaining_x = allocate_denominations(x, denominations)
    
    print("\nDenominations used for end day sales (x):")
    print(allocated_x)
    
    if remaining_x > 0:
        print(f"Not enough denominations to allocate {x}. Remaining amount: {remaining_x}")
    else:
        # Calculate remaining denominations sum
        remaining_sum = calculate_remaining(denominations)
        
        if remaining_sum > 100:
            print(f"\nValue is more by {round(remaining_sum - 100, 2)}")
        elif remaining_sum == 100:
            print("\nValue is exactly 100")
        else:
            print(f"\nValue is less by {round(100 - remaining_sum, 2)}")
        
        print("\nRemaining denominations:")
        print(denominations)

if __name__ == "__main__":
    main()
