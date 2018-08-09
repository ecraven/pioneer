shipClasses = /tmp/ship_class_light_freighter.svg /tmp/ship_class_medium_freighter.svg /tmp/ship_class_heavy_freighter.svg \
  /tmp/ship_class_light_fighter.svg /tmp/ship_class_medium_fighter.svg /tmp/ship_class_heavy_fighter.svg \
  /tmp/ship_class_light_courier.svg /tmp/ship_class_medium_courier.svg /tmp/ship_class_heavy_courier.svg \
  /tmp/ship_class_light_passenger_shuttle.svg /tmp/ship_class_medium_passenger_shuttle.svg /tmp/ship_class_heavy_passenger_shuttle.svg \
  /tmp/ship_class_light_passenger_transport.svg /tmp/ship_class_medium_passenger_transport.svg /tmp/ship_class_heavy_passenger_transport.svg \
  /tmp/ship_class_light_cargo_shuttle.svg /tmp/ship_class_medium_cargo_shuttle.svg /tmp/ship_class_heavy_cargo_shuttle.svg

exportShipClasses: icons.svg $(shipClasses)

clean:
	rm -f $(shipClasses)

/tmp/%.svg: icons.svg
	inkscape $< -i $* -j --vacuum-defs -l $@
	sed -i -e 's/stroke:#ffffff/stroke:#111111/g' -e 's/fill:#ffffff/fill:#111111/g' $@
