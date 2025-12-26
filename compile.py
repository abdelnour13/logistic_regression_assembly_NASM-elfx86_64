import subprocess
import tempfile
import os

SRC_DIR = 'src'

def main():

    if os.path.exists('main'):
        os.remove('main')

    with tempfile.TemporaryDirectory() as tempdir:

        for file in os.listdir(SRC_DIR):

            input = os.path.join(SRC_DIR, file)
            output = os.path.join(tempdir, f'{os.path.splitext(file)[0]}.o')

            cmd = ['nasm', '-f', 'elf64', input, '-o', output]

            process = subprocess.run(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )

            if process.returncode == 1:
                print(f"Error when compiling {input} : {process.stderr.strip()} \n CMD : {' '.join(cmd)}")
                return
            
        objects = [os.path.join(tempdir, file) for file in os.listdir(tempdir)]
            
        process = subprocess.run(
            ["ld", "-s", "-o", "main", *objects],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )

        if process.returncode == 1:
            print(f"Linking failed with error : {process.stderr.strip()}")
            return
            
if __name__ == '__main__':
    main()