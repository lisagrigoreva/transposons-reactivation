import sys

def process_fastq(input_file, output_file):
    UMI = ""
    q = "I" * 12  # Quality string to repeat
    with open(input_file, "r") as infile, open(output_file, "w") as outfile:
        lines = infile.readlines()
        for i, line in enumerate(lines):
            r_n = (i % 4) + 1  # Line type within a record
            if r_n == 1:  # Header line
                first_part = line.split(" ")[0]
                UMI = first_part.split("UMI_")[-1][:12]
                outfile.write(line)
            elif r_n == 2:  # Sequence line
                modified_sequence = f"{UMI}{UMI}{UMI}{line.strip()}\n"
                outfile.write(modified_sequence)
            elif r_n == 3:  # "+" line (delimiter)
                outfile.write(line)
            elif r_n == 4:  # Quality line
                modified_quality = f"{q}{q}{q}{line.strip()}\n"
                outfile.write(modified_quality)

if __name__ == "__main__":
    input_fastq = sys.argv[1]
    output_fastq = sys.argv[2]
    process_fastq(input_fastq, output_fastq)

