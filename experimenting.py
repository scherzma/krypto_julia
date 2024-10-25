import re


def subtract_one(match):
    return str(int(match.group()) - 1)

def modify_numbers(input_string):
    return re.sub(r'\d+', subtract_one, input_string)

# Example usage
original = """
1 2 3 4 5 6 7 8                9 10 11 12 13 14 15 16                             17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32        
33 34 35 36 37 38 39 40        41 42 43 44 45 46 47 48                    49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64      
65 66 67 68 69 70 71 72        73 74 75 76 77 78 79 80                    81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96       
97 98 99 100 101 102 103 104   105 106 107 108 109 110 111 112       113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128


121 122 123 124 125 126 127 128   113 114 115 116 117 118 119 120   105 106 107 108 109 110 111 112    97 98 99 100 101 102 103 104 
89 90 91 92 93 94 95 96     81 82 83 84 85 86 87 88                 73 74 75 76 77 78 79 80            65 66 67 68 69 70 71 72    
57 58 59 60 61 62 63 64     49 50 51 52 53 54 55 56                 41 42 43 44 45 46 47 48            33 34 35 36 37 38 39 40    
25 26 27 28 29 30 31 32     17 18 19 20 21 22 23 24                 9 10 11 12 13 14 15 16             1 2 3 4 5 6 7 8

"""
modified = modify_numbers(original)
print("Modified string:", modified)


def pairwise_addition(str1, str2):
    # Split the strings into lists of numbers, handling multiple spaces
    nums1 = [int(num) for num in str1.split()]
    nums2 = [int(num) for num in str2.split()]

    # Ensure both lists have the same length by padding with zeros
    max_length = max(len(nums1), len(nums2))
    nums1 += [0] * (max_length - len(nums1))
    nums2 += [0] * (max_length - len(nums2))

    # Perform pairwise addition
    result = [a + b for a, b in zip(nums1, nums2)]

    return result


# Example usage
string1 = "0 1 2 3 4 5 6 7                8 9 10 11 12 13 14 15 "
string2 = "120 121 122 123 124 125 126 127   112 113 114 115 116 117 118 119"

result = pairwise_addition(string1, string2)
print("Pairwise addition result:", result)