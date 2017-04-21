#include <chibi/sexp.h>
#include <string>
#ifndef CHIBI_H
#define CHIBI_H
class Chibi {
	sexp ctx;
public:
	Chibi();
	void defun(std::string name, sexp_proc1 fun, int num_args);
	void eval(std::string string);
};
#endif // CHIBI_H
