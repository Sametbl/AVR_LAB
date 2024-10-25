from itertools import product

def find_best_abc(target_cycles):
    best_A = None
    best_B = None
    best_C = None
    min_error = float('inf')

    # Loop over all possible values of A, B, C (from 1 to 255)
    for A in range(0, 256):
        for B in range(0, 256):
            for C in range(0, 256):
                total_cycles = 3*A*B*C + 3*B*C + 3*C + 6      # The total cycles
                error = abs(total_cycles - target_cycles)     # The error between the total cycles and the target cycles
                
                # If the current error is smaller than the best one, update the best values
                if error < min_error:
                    min_error = error
                    best_A, best_B, best_C = A, B, C
                
                if min_error == 0:                            # Early exit if we find an exact match
                    break

    return best_A, best_B, best_C, min_error




# Input desired cycles
print(f"Maximum delay is   49 939 971   cycles")
target_cycles = int(input("Enter the desired number of cycles: "))

A, B, C, error = find_best_abc(target_cycles)

print(f"Best A = {A}")
print(f"Best B = {B}")
print(f"Best C = {C}")
print(f"Achieved cycles = {3*A*B*C + 3*B*C + 3*C + 6}")
print(f"Error from desired cycles = {error}")
