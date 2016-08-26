#include "PiGui.h"
#include "imgui/imgui_internal.h"

ImFont *PiGui::pionillium12 = nullptr;
ImFont *PiGui::pionillium15 = nullptr;
ImFont *PiGui::pionillium18 = nullptr;
ImFont *PiGui::pionillium30 = nullptr;
ImFont *PiGui::pionillium36 = nullptr;
ImFont *PiGui::pionicons12 = nullptr;
//ImFont *PiGui::pionicons18 = nullptr;
ImFont *PiGui::pionicons30 = nullptr;

int PiGui::RadialPopupSelectMenu(const ImVec2& center, std::string popup_id, std::vector<std::string> items, ImFont *itemfont, std::vector<std::string> tooltips)
{
  int ret = -1;

  // FIXME: Missing a call to query if Popup is open so we can move the PushStyleColor inside the BeginPopupBlock (e.g. IsPopupOpen() in imgui.cpp)
  // FIXME: Our PathFill function only handle convex polygons, so we can't have items spanning an arc too large else inner concave edge artifact is too visible, hence the ImMax(7,items_count)
  ImGui::PushStyleColor(ImGuiCol_WindowBg, ImVec4(0,0,0,0));
	ImGui::PushStyleColor(ImGuiCol_PopupBg, ImVec4(0,0,0,0));
  ImGui::PushStyleColor(ImGuiCol_Border, ImVec4(0,0,0,0));
  if (ImGui::BeginPopup(popup_id.c_str()))
    {
      const ImVec2 drag_delta = ImVec2(ImGui::GetIO().MousePos.x - center.x, ImGui::GetIO().MousePos.y - center.y);
      const float drag_dist2 = drag_delta.x*drag_delta.x + drag_delta.y*drag_delta.y;

      const ImGuiStyle& style = ImGui::GetStyle();
      const float RADIUS_MIN = 20.0f;
      const float RADIUS_MAX = 90.0f;
      const float RADIUS_INTERACT_MIN = 20.0f;
      const int ITEMS_MIN = 5;
			const float border_inout = 12.0f;
			const float border_thickness = 4.0f;
      ImDrawList* draw_list = ImGui::GetWindowDrawList();
      draw_list->PushClipRectFullScreen();
      draw_list->PathArcTo(center, (RADIUS_MIN + RADIUS_MAX)*0.5f, 0.0f, IM_PI*2.0f*0.99f, 64);   // FIXME: 0.99f look like full arc with closed thick stroke has a bug now
      draw_list->PathStroke(ImColor(18,44,67,210), true, RADIUS_MAX - RADIUS_MIN);

      const float item_arc_span = 2*IM_PI / ImMax(ITEMS_MIN, items.size());
      float drag_angle = atan2f(drag_delta.y, drag_delta.x);
      if (drag_angle < -0.5f*item_arc_span)
        drag_angle += 2.0f*IM_PI;
      //ImGui::Text("%f", drag_angle);    // [Debug]

      int item_hovered = -1;
			int item_n = 0;
			for(std::string item : items) {
          const char* item_label = item.c_str();
					const char* tooltip = tooltips.at(item_n).c_str();
          const float inner_spacing = style.ItemInnerSpacing.x / RADIUS_MIN / 2;
          const float item_inner_ang_min = item_arc_span * (item_n - 0.5f + inner_spacing);
          const float item_inner_ang_max = item_arc_span * (item_n + 0.5f - inner_spacing);
          const float item_outer_ang_min = item_arc_span * (item_n - 0.5f + inner_spacing * (RADIUS_MIN / RADIUS_MAX));
          const float item_outer_ang_max = item_arc_span * (item_n + 0.5f - inner_spacing * (RADIUS_MIN / RADIUS_MAX));

          bool hovered = false;
          if (drag_dist2 >= RADIUS_INTERACT_MIN*RADIUS_INTERACT_MIN) {
              if (drag_angle >= item_inner_ang_min && drag_angle < item_inner_ang_max)
                hovered = true;
            }
          bool selected = false;

          int arc_segments = (int)(64 * item_arc_span / (2*IM_PI)) + 1;
					//          draw_list->PathArcTo(center, RADIUS_MAX - style.ItemInnerSpacing.x, item_outer_ang_min, item_outer_ang_max, arc_segments);
          //          draw_list->PathArcTo(center, RADIUS_MIN + style.ItemInnerSpacing.x, item_inner_ang_max, item_inner_ang_min, arc_segments);
					draw_list->PathArcTo(center, RADIUS_MAX - border_inout, item_outer_ang_min, item_outer_ang_max, arc_segments);
          draw_list->PathArcTo(center, RADIUS_MIN + border_inout, item_inner_ang_max, item_inner_ang_min, arc_segments);

          //draw_list->PathFill(window->Color(hovered ? ImGuiCol_HeaderHovered : ImGuiCol_FrameBg));
          draw_list->PathFill(hovered ? ImColor(102,147,189) : selected ? ImColor(48,81,111) : ImColor(48,81,111));
					if(hovered) {
						// draw outer / inner extra segments
						draw_list->PathArcTo(center, RADIUS_MAX - border_thickness, item_outer_ang_min, item_outer_ang_max, arc_segments);
						draw_list->PathStroke(ImColor(102,147,189), false, border_thickness);
						draw_list->PathArcTo(center, RADIUS_MIN + border_thickness, item_outer_ang_min, item_outer_ang_max, arc_segments);
						draw_list->PathStroke(ImColor(102,147,189), false, border_thickness);
					}
					ImGui::PushFont(itemfont);
          ImVec2 text_size = ImGui::CalcTextSize(item_label);
          ImVec2 text_pos = ImVec2(
                                   center.x + cosf((item_inner_ang_min + item_inner_ang_max) * 0.5f) * (RADIUS_MIN + RADIUS_MAX) * 0.5f - text_size.x * 0.5f,
                                   center.y + sinf((item_inner_ang_min + item_inner_ang_max) * 0.5f) * (RADIUS_MIN + RADIUS_MAX) * 0.5f - text_size.y * 0.5f);
					//          draw_list->AddImage((void*)m_texture, text_pos, ImVec2(text_pos.x+x,text_pos.y+y)); ImGui::SameLine();
					draw_list->AddText(text_pos, ImColor(255,255,255), item_label);
					ImGui::PopFont();
          if (hovered) {
            item_hovered = item_n;
						ImGui::SetTooltip(tooltip);
						//   draw_list->AddText(text_pos, ImColor(255,255,255), item_label);

          }
					item_n++;
        }
      draw_list->PopClipRect();

      if (ImGui::IsMouseReleased(1))
        {
          ImGui::CloseCurrentPopup();
          ret = item_hovered;
        }
      ImGui::EndPopup();
    }
  ImGui::PopStyleColor(3);
  return ret;
}

bool PiGui::CircularSlider(const ImVec2 &center, float *v, float v_min, float v_max) {
      ImDrawList* draw_list = ImGui::GetWindowDrawList();
			ImGuiWindow* window = ImGui::GetCurrentWindow();
			const ImGuiID id = window->GetID("circularslider");
			draw_list->AddCircle(center, 17, ImColor(100, 100, 100), 128, 12.0);
			draw_list->PathArcTo(center, 17, 0, M_PI * 2.0 * (*v - v_min) / (v_max - v_min), 64);
			draw_list->PathStroke(ImColor(200,200,200), false, 12.0);
			return ImGui::SliderBehavior(ImRect(center.x - 17, center.y - 17, center.x + 17, center.y + 17), id, v, v_min, v_max, 1.0, 4);
}
