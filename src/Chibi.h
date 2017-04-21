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
	void init(double delta);
	void game(double delta);
};
#endif // CHIBI_H
