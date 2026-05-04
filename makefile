

arithmetic_sequence.o: arithmetic_sequence.asm
	nasm -f elf64 -g -w+all -w+error -o arithmetic_sequence.o arithmetic_sequence.asm

init_test.o: init_test.c
	gcc -c init_test.c -o init_test.o

init_test: init_test.o arithmetic_sequence.o
	gcc -z noexecstack init_test.o arithmetic_sequence.o -o test -no-pie

arithmetic_sequence_example.o:
	g++ -c -Wall -Wextra -std=c++23 -O2 -o arithmetic_sequence_example_cpp.o arithmetic_sequence_example.cpp

test: arithmetic_sequence.o arithmetic_sequence_example.o
	g++ -z noexecstack -o arithmetic_sequence_example_cpp arithmetic_sequence_example_cpp.o arithmetic_sequence.o -lgmp

arithmetic_sequence_example_c.o : arithmetic_sequence_example.c
	gcc -c -Wall -Wextra -std=c23 -O2 -o arithmetic_sequence_example_c.o arithmetic_sequence_example.c

test_c: arithmetic_sequence_example_c.o arithmetic_sequence.o 
	gcc -z noexecstack -o arithmetic_sequence_example_c arithmetic_sequence_example_c.o arithmetic_sequence.o

clean:
	rm -rf *_test *.o arithmetic_sequence_example_c arithmetic_sequence_example_cpp test
	
