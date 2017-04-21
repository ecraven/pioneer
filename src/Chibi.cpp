#include "Chibi.h"
#include <chibi/eval.h>
#include <iostream>
#include "imgui/imgui.h"
#include "graphics/Graphics.h"
#include "Player.h"
#include "Game.h"
#include "Pi.h"
#include "PiGui.h"

static sexp v3_sexp;
static sexp init_sexp;
static sexp game_sexp;
static sexp sym_no_title_bar;
static sexp sym_no_resize;
static sexp sym_no_move;
static sexp sym_plot_histogram;
static sexp sym_frame_bg;

static sexp ui_screen_size(sexp ctx, sexp self, sexp n) {
	sexp width = sexp_make_fixnum(Graphics::GetScreenWidth());
	sexp height = sexp_make_fixnum(Graphics::GetScreenHeight());
	return sexp_apply(ctx, v3_sexp, sexp_cons(ctx, width, sexp_cons(ctx, height, sexp_cons(ctx, SEXP_ZERO, SEXP_NULL))));
}

static sexp ui_begin(sexp ctx, sexp self, sexp n, sexp name, sexp params) {
	int p = 0;
	while(params != SEXP_NULL) {
		sexp c = sexp_car(params);
		if(c == sym_no_title_bar) {
			p |= ImGuiWindowFlags_NoTitleBar;
		} else if(c == sym_no_resize) {
			p |= ImGuiWindowFlags_NoResize;
		} else if(c == sym_no_move) {
			p |= ImGuiWindowFlags_NoMove;
		}
		params = sexp_cdr(params);
	}
	ImGui::Begin(sexp_string_data(name), nullptr, p);
	return SEXP_VOID;
}
double sexp_num(sexp x) {
	if(sexp_fixnump(x)) {
		return sexp_unbox_fixnum(x);
	}
	if(sexp_flonump(x)) {
		return sexp_flonum_value(x);
	}
  std::cout << "XXXXXX: Neither fixnum nor flonum." << std::endl;
	return -1;
}

static sexp ui_end(sexp ctx, sexp self, sexp n) {
	ImGui::End();
	return SEXP_VOID;
}
static ImFont *get_font(std::string fontname, int size) {
	ImFont *font;
	if(!fontname.compare("pionillium")) {
		switch(size) {
		case 12: font = PiGui::pionillium12; break;
		case 15: font = PiGui::pionillium15; break;
		case 18: font = PiGui::pionillium18; break;
		case 30: font = PiGui::pionillium30; break;
		case 36: font = PiGui::pionillium36; break;
		default:
			Error("Pionillium at size %d not found.\n", size);
		}
	} else if(!fontname.compare("orbiteer")) {
		switch(size) {
		case 18: font = PiGui::orbiteer18; break;
		case 30: font = PiGui::orbiteer30; break;
		default:
			Error("Orbiteer at size %d not found.\n", size);
		}
	} else
		Error("Unknown font %s\n", fontname.c_str());
	return font;
}

static sexp ui_push_font(sexp ctx, sexp self, sexp n, sexp name, sexp size) {
	std::string fontname = sexp_string_data(name);
	int sze = sexp_unbox_fixnum(size);
	ImFont *font = get_font(fontname, sze);
	ImGui::PushFont(font);
	return SEXP_VOID;
}

static sexp ui_pop_font(sexp ctx, sexp self, sexp n) {
	ImGui::PopFont();
	return SEXP_VOID;
}

static sexp ui_push_style_color(sexp ctx, sexp self, sexp n, sexp name, sexp value) {
	int style = 0;
	if(name == sym_plot_histogram) {
		style = ImGuiCol_PlotHistogram;
	} else if(name == sym_frame_bg) {
		style = ImGuiCol_FrameBg;
	}
	ImU32 color = sexp_unbox_fixnum(value);
	ImGui::PushStyleColor(style, ImColor(color));
	return SEXP_VOID;
}
static sexp ui_pop_style_color(sexp ctx, sexp self, sexp n, sexp number) {
	ImGui::PopStyleColor(sexp_unbox_fixnum(number));
	return SEXP_VOID;
}

static sexp ui_text(sexp ctx, sexp self, sexp n, sexp text) {
	ImGui::Text("%s", sexp_string_data(text));
	return SEXP_VOID;
}

static sexp ui_set_next_window_pos(sexp ctx, sexp self, sexp n, sexp v3) {
	ImGui::SetNextWindowPos(ImVec2(sexp_num(sexp_slot_ref(v3, 0)),sexp_num(sexp_slot_ref(v3, 1))));
	return SEXP_VOID;
}
static sexp ui_set_next_window_size(sexp ctx, sexp self, sexp n, sexp v3) {
	ImGui::SetNextWindowSize(ImVec2(sexp_num(sexp_slot_ref(v3, 0)),sexp_num(sexp_slot_ref(v3, 1))));
	return SEXP_VOID;
}
static sexp ui_dummy(sexp ctx, sexp self, sexp n, sexp v3) {
	ImGui::Dummy(ImVec2(sexp_num(sexp_slot_ref(v3, 0)),sexp_num(sexp_slot_ref(v3, 1))));
	return SEXP_VOID;
}
static sexp ui_same_line(sexp ctx, sexp self, sexp n) {
	ImGui::SameLine();
	return SEXP_VOID;
}
static sexp ui_progress_bar(sexp ctx, sexp self, sexp n, sexp fraction, sexp v3_size, sexp text) {
	ImGui::ProgressBar(sexp_flonum_value(fraction), ImVec2(sexp_num(sexp_slot_ref(v3_size, 0)),sexp_num(sexp_slot_ref(v3_size, 1))), sexp_string_data(text));
	return SEXP_VOID;
}
static sexp ui_screen_width(sexp ctx, sexp self, sexp n) {
	return sexp_make_fixnum(Graphics::GetScreenWidth());
}
static sexp ui_calc_text_size(sexp ctx, sexp self, sexp n, sexp text) {
	const ImVec2 &size = ImGui::CalcTextSize(sexp_string_data(text));
	return sexp_apply(ctx, v3_sexp, sexp_cons(ctx, sexp_make_flonum(ctx, size.x), sexp_cons(ctx, sexp_make_flonum(ctx, size.y), sexp_cons(ctx, SEXP_ZERO, SEXP_NULL))));
}

static sexp ui_screen_height(sexp ctx, sexp self, sexp n) {
	return sexp_make_fixnum(Graphics::GetScreenHeight());
}
static sexp ui_player(sexp ctx, sexp self, sexp n) {
	return sexp_make_cpointer(ctx, sexp_num(sexp_opcode_arg1_type(self)), Pi::game->GetPlayer(), SEXP_FALSE, 0);
}
static sexp ui_player_max_delta_v(sexp ctx, sexp self, sexp n) {
	Player *p = Pi::game->GetPlayer();
	const ShipType *st = p->GetShipType();
	double ev = st->effectiveExhaustVelocity * log((double(p->GetStats().static_mass + st->fuelTankMass)) / (p->GetStats().static_mass));
	return sexp_make_flonum(ctx, ev);
}
static sexp ui_player_current_delta_v(sexp ctx, sexp self, sexp n) {
	Player *p = Pi::game->GetPlayer();
	double ev = p->GetVelocityRelTo(p->GetFrame()).Length();
	return sexp_make_flonum(ctx, ev);
}
static sexp ui_player_remaining_delta_v(sexp ctx, sexp self, sexp n) {
	Player *player = Pi::game->GetPlayer();
	const double fuelmass = 1000*player->GetShipType()->fuelTankMass * player->GetFuel();
	double ev = player->GetShipType()->effectiveExhaustVelocity * log(player->GetMass()/(player->GetMass()-fuelmass));
	return sexp_make_flonum(ctx, ev);
}

Chibi::Chibi() {
	std::cout << "Starting chibi..." << std::endl;
	ctx = sexp_make_eval_context(nullptr, nullptr, nullptr, 0, 0);
	sexp_load_standard_env(ctx, nullptr, SEXP_SEVEN);
	sexp_load_standard_ports(ctx, NULL, stdin, stdout, stderr, 0);
	sexp file_path = sexp_c_string(ctx, "src/ui.scm", -1);
	if(sexp_exceptionp(file_path)) {
		sexp_print_exception(ctx, file_path, sexp_current_output_port(ctx));
	}
	defun("ui:begin", (sexp_proc1)ui_begin, 2);
	defun("ui:end", (sexp_proc1)ui_end, 0);
	defun("ui:push-font", (sexp_proc1)ui_push_font, 2);
	defun("ui:pop-font", (sexp_proc1)ui_pop_font, 0);
	defun("ui:push-style-color", (sexp_proc1)ui_push_style_color, 2);
	defun("ui:pop-style-color", (sexp_proc1)ui_pop_style_color, 1);
	defun("ui:text", (sexp_proc1)ui_text, 1);
	defun("ui:dummy", (sexp_proc1)ui_dummy, 1);
	defun("ui:same-line", (sexp_proc1)ui_same_line, 0);
	defun("ui:calc-text-size", (sexp_proc1)ui_calc_text_size, 1);
	defun("ui:progress-bar", (sexp_proc1)ui_progress_bar, 3);
	defun("ui:set-next-window-pos", (sexp_proc1)ui_set_next_window_pos, 1);
	defun("ui:set-next-window-size", (sexp_proc1)ui_set_next_window_size, 1);
	defun("ui:screen-width", (sexp_proc1)ui_screen_width, 0);
	defun("ui:screen-height", (sexp_proc1)ui_screen_height, 0);
	defun("ui:screen-size", (sexp_proc1)ui_screen_size, 0);
	defun("ui:player", (sexp_proc1)ui_player, 0);
	defun("ui:player-max-delta-v", (sexp_proc1)ui_player_max_delta_v, 0);
	defun("ui:player-current-delta-v", (sexp_proc1)ui_player_current_delta_v, 0);
	defun("ui:player-remaining-delta-v", (sexp_proc1)ui_player_remaining_delta_v, 0);
	if(false) {
		sexp env = sexp_context_env(ctx);
		sexp v3 = sexp_register_simple_type(ctx, sexp_c_string(ctx, "v3", -1), SEXP_FALSE, sexp_cons(ctx, sexp_intern(ctx, "x", -1), sexp_cons(ctx, sexp_intern(ctx, "y", -1), sexp_cons(ctx, sexp_intern(ctx, "z", -1), SEXP_NULL))));
		sexp_env_define(ctx, env, sexp_intern(ctx, "<v3>", -1), v3);
		sexp op = sexp_make_constructor(ctx, sexp_c_string(ctx, "make-v3", -1), v3);
		sexp_env_define(ctx, env, sexp_intern(ctx, "make-v3", -1), op);
		op = sexp_make_getter(ctx, sexp_c_string(ctx, "v3-x", -1), v3, sexp_make_fixnum(0));
		sexp_env_define(ctx, env, sexp_intern(ctx, "v3-x", -1), op);
		op = sexp_make_getter(ctx, sexp_c_string(ctx, "v3-y", -1), v3, sexp_make_fixnum(1));
		sexp_env_define(ctx, env, sexp_intern(ctx, "v3-y", -1), op);
		op = sexp_make_getter(ctx, sexp_c_string(ctx, "v3-z", -1), v3, sexp_make_fixnum(2));
		sexp_env_define(ctx, env, sexp_intern(ctx, "v3-z", -1), op);
		op = sexp_make_setter(ctx, sexp_c_string(ctx, "v3-x!", -1), v3, sexp_make_fixnum(0));
		sexp_env_define(ctx, env, sexp_intern(ctx, "v3-x!", -1), op);
		op = sexp_make_setter(ctx, sexp_c_string(ctx, "v3-y!", -1), v3, sexp_make_fixnum(1));
		sexp_env_define(ctx, env, sexp_intern(ctx, "v3-y!", -1), op);
		op = sexp_make_setter(ctx, sexp_c_string(ctx, "v3-z!", -1), v3, sexp_make_fixnum(2));
		sexp_env_define(ctx, env, sexp_intern(ctx, "v3-z!", -1), op);
		op = sexp_make_type_predicate(ctx, sexp_c_string(ctx, "v3?", -1), v3);
		sexp_env_define(ctx, env, sexp_intern(ctx, "v3?", -1), op);
	}
	sexp load = sexp_load(ctx, file_path, NULL);
	if(sexp_exceptionp(load)) {
		sexp_print_exception(ctx, load, sexp_current_output_port(ctx));
	}
	v3_sexp = sexp_env_ref(ctx, sexp_context_env(ctx), sexp_intern(ctx, "v3", -1), SEXP_FALSE);
	init_sexp = sexp_env_ref(ctx, sexp_context_env(ctx), sexp_intern(ctx, "init", -1), SEXP_FALSE);
	game_sexp = sexp_env_ref(ctx, sexp_context_env(ctx), sexp_intern(ctx, "game", -1), SEXP_FALSE);
	sym_no_title_bar = sexp_intern(ctx, "no-title-bar", -1);
	sym_no_resize = sexp_intern(ctx, "no-resize", -1);
	sym_no_move = sexp_intern(ctx, "no-move", -1);
	sym_plot_histogram = sexp_intern(ctx, "plot-histogram", -1);
	sym_frame_bg = sexp_intern(ctx, "frame_bg", -1);
}
void Chibi::defun(std::string name, sexp_proc1 fun, int num_args) {
	sexp res = sexp_define_foreign(ctx, sexp_context_env(ctx), name.c_str(), num_args, fun);
	if(sexp_exceptionp(res)) {
	 	sexp_print_exception(ctx, res, sexp_current_output_port(ctx));
	}
}
void Chibi::eval(std::string string) {
	sexp res = sexp_eval_string(ctx, string.c_str(), -1, nullptr);
	if(sexp_exceptionp(res)) {
	 	sexp_print_exception(ctx, res, sexp_current_output_port(ctx));
	}
}
void Chibi::game(double delta) {
	sexp_apply1(ctx, game_sexp, sexp_make_flonum(ctx, delta));
}
void Chibi::init(double delta) {
	sexp_apply1(ctx, init_sexp, sexp_make_flonum(ctx, delta));
}
