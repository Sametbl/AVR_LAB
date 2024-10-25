


def find_best_prescaler_and_ocr(desired_cycles):
    prescalers = [1, 8, 64, 256, 1024]
    best_prescaler = None
    best_ocr_value = None
    best_cycles_diff = float('inf')
    best_actual_cycles = None

    # Loop through each prescaler value and OCR values from 0 to 65535 (16-bit timer)
    for prescaler in prescalers:
        for ocr_value in range(0, 255):
            actual_cycles = prescaler * (ocr_value + 1) + 21
            cycles_diff = abs(actual_cycles - desired_cycles)

            if cycles_diff < best_cycles_diff:
                best_cycles_diff = cycles_diff
                best_prescaler   = prescaler
                best_ocr_value   = ocr_value
                best_actual_cycles = actual_cycles

    return best_prescaler, best_ocr_value, best_actual_cycles, best_cycles_diff

# Example usage
desired_cycles = int(input("Enter the desired number of cycles: "))
best_prescaler, best_ocr_value, best_actual_cycles, best_cycles_diff = find_best_prescaler_and_ocr(desired_cycles)

print(f"Best Prescaler: {best_prescaler}")
print(f"Best OCR Value: {best_ocr_value}")
print(f"Actual Cycles:  {best_actual_cycles}")
print(f"Difference from Desired Cycles: {best_cycles_diff}")
