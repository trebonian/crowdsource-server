=begin
This will be a tile carving utility, or a set of rules
to map tile carvings together into the database.
=end


#temporary
require 'rubygems'
require 'models'


itypes = ['p','t']
xrange = 0..9
yrange = 0..12

# 700 × 550 png images
xwidth = 700
ywidth = 550

xrange.each do |x|
  yrange.each do |y|
    itypes.each do |itype|
      layer = Layer.first(:itype => itype, :chip_id =>1)
      raise "bad itype, failed to find layer" if not layer

      t = Tile.new
      t.layer_id = layer.id
      
      t.x_coord = x
      t.y_coord = y
      
      t.sizex = xwidth
      t.minx = x*t.sizex
      t.sizey = ywidth
      t.miny = y*t.sizey
      
      raise "failed to save" if not t.save
    end
  end
end
