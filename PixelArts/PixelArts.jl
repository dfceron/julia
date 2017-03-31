module PixelArts

function create_canvas(id::String, vunits::Int, hunits::Int, height::Int = 250, width::Int = 250)
    display("text/html", """
    <div class="usersvg">
    <svg id='$id' width='$(width)' height='$(height)' viewbox='0 0 $hunits $vunits'></svg>
    </div>
    <script> 
    requirejs.config({paths: {d3: "https://d3js.org/d3.v3.min.js?noext"}});  
    </script>
    """)
end
function create_canvas(vunits::Int, hunits::Int, height::Int = 250, width::Int = 250)
    id = "canvas" * randstring(3)
    create_canvas(id, vunits, hunits, height, width)
    return id
end
export create_canvas

function remove_element_by_id(id::String)
    display("text/html", """
    <script> 
    var x = document.querySelector(".usersvg #$id");
    x.parentNode.removeChild(x);
    """)
end
export remove_element_by_id

function add_pixels(id::String, i::Int, j::Int, colour::Any = "black")
    display("text/javascript", """
    var svg = document.getElementById('$id'); 
    var newElement = document.createElementNS("http://www.w3.org/2000/svg", 'rect'); 
    newElement.setAttribute('width','1'); 
    newElement.setAttribute('height','1'); 
    newElement.setAttribute('x','$(j - 1)'); 
    newElement.setAttribute('y','$(i - 1)'); 
    newElement.style.fill = '$colour'; 
    svg.appendChild(newElement);
    """) 
end
function add_pixels(id::String, pos::Array{Array{Int, 1}, 1}, colour::Any = ["black"])
    nc, n = size(colour, 1), size(pos, 1)
    if (nc == 1) colour = [colour[1] for x in 1:n] end
    if (1 < nc < n) error("invalid length for colour") end
    s = "var svg=document.getElementById('$id');var newElement;"
    for i in 1:n
        p = pos[i]
        s *= 
        """
        newElement = document.createElementNS("http://www.w3.org/2000/svg", 'rect'); 
        newElement.setAttribute('width','1'); 
        newElement.setAttribute('height','1'); 
        newElement.setAttribute('x','$(p[2] - 1)'); 
        newElement.setAttribute('y','$(p[1] - 1)'); 
        newElement.style.fill = '$(colour[i])'; 
        svg.appendChild(newElement);
        """
    end
    display("text/javascript", s) 
end
function add_pixels(id::String, colour_array::Array)
    vunits, hunits = size(colour_array)
    pos = [[i,j] for i in 1:vunits for j in 1:hunits]
    colour = [colour_array[x...] for x in pos]
    add_pixels(id, pos, colour)
end
export add_pixels

function render_bg(colour_array::Array{Any, 2}, width::Int = 250, height::Int = 250)
    vunits, hunits = size(array)
    pos = [[i,j] for i in 1:vunits for j in 1:hunits]
    colour = [colour_array[x...] for x in pos]
    new_canvas = create_canvas(vunits, hunits, height, width)
    add_pixels(new_canvas, pos, colour)
    return new_canvas
end
function render_bg(array::Any, colour_dict::Dict, width::Int = 250, height::Int = 250)
    vunits, hunits = size(array)
    pos = [[i,j] for i in 1:vunits for j in 1:hunits]
    colour = [colour_dict[array[x...]] for x in pos]
    new_canvas = create_canvas(vunits, hunits, height, width)
    add_pixels(new_canvas, pos, colour)
    return new_canvas
end
function render_bg(bg_name::String, width::Int = 250, height::Int = 250)
    if !(bg_name in ["right_turn", "circuit"])
        error("Invalid bg_name")
    end
    array = readcsv(joinpath(dirname(@__FILE__), "files", "$(bg_name).csv"))
    colour_dict = readcsv(joinpath(dirname(@__FILE__), "files", "$(bg_name)_colours.csv"))
    colour_dict = Dict(zip(colour_dict[:,1], colour_dict[:,2]))
    return render_bg(array, colour_dict, width, height)
end
export render_bg

function bg_colour_array(bg_name::String)
    if !(bg_name in ["right_turn", "circuit"])
        error("Invalid bg_name")
    end
    array = readcsv(joinpath(dirname(@__FILE__), "files", "$(bg_name).csv"))
    colour_dict = readcsv(joinpath(dirname(@__FILE__), "files", "$(bg_name)_colours.csv"))
    colour_dict = Dict(zip(colour_dict[:,1], colour_dict[:,2]))
    vunits, hunits = size(array)
    pos = [[i,j] for i in 1:vunits, j in 1:hunits]
    colour_array = map(x -> colour_dict[array[x...]], pos)
    return colour_array, pos, array
end
export bg_colour_array

function add_svg_element(element_id::String, canvas_id::String, element_type::String, i::Real = 1, j::Real = 1; attr = Dict(), style = Dict())
    if !(element_type in ["circle", "rect", "path", "line"]) error("Element type $(element_type) not supported") end
    s = """d3.select(".usersvg #$canvas_id").append("$element_type")"""
    s *= """.attr("id", "$element_id").attr("transform", "translate($(i-1) $(j-1))")"""
    for key in keys(attr) s*= """.attr("$key", "$(attr[key])")""" end
    for key in keys(style) s*= """.attr("$key", "$(style[key])")""" end
    display("text/html", """<script>require(["d3"], function(d3) {$s;});</script>""") 
end
function add_svg_element(canvas_id::String, element_type::String, i::Real = 0, j::Real = 0; attr = Dict(), style = Dict())
    if !(element_type in ["circle", "rect", "path", "line"]) error("Element type $(element_type) not supported") end
    element_id = "element" * randstring(3)
    add_svg_element(element_id, canvas_id, element_type, i, j, attr = attr, style = style)
    return element_id
end
export add_svg_element

function set_attr(element_id::String, attr)
    s = """d3.select(".usersvg #$element_id")"""
    for key in keys(attr) s*= """.attr("$key", "$(attr[key])")""" end
    display("text/html", """<script>require(["d3"], function(d3) {$s;});</script>""") 
end
function set_style(element_id::String, style)
    s = """d3.select(".usersvg #$element_id")"""
    for key in keys(style) s*= """.attr("$key", "$(attr[style])")""" end
    display("text/html", """<script>require(["d3"], function(d3) {$s;});</script>""") 
end
function translate_element(element_id::String, hmove::Int, vmove::Int)
    display("text/html", """
    <script>
    require(["d3"], function(d3) {
        d3.select(".usersvg #$element_id").attr("transform", "translate($(vmove-1) $(hmove-1))");
    });
    </script>
    """) 
end
export set_attr, set_style, translate_element

function add_pixel_cross(element_id::String, canvas_id::String, i::Int, j::Int, colour::Any = "black")
    attr = Dict("d" => "M0.5 0 L0.5 1 M0 0.5 L1 0.5", "transform" => "translate($(j-1) $(i-1))")
    style = Dict("stroke" => "$colour", "stroke-width" => 0.2)
    add_svg_element(element_id, canvas_id, "path", i, j, attr = attr, style = style)
end
function add_pixel_cross(canvas_id::String, i::Int, j::Int, colour::Any)
    element_id = "pixel_cross" * randstring(3)
    add_pixel_cross(element_id, canvas_id, i, j, colour)
    return element_id
end
export add_pixel_cross

function add_pixel_arrow(element_id::String, canvas_id::String, i::Int, j::Int, rotate::Real = 0, colour::Any = "black")
    attr = Dict("d" => "M0 0 L0 0.5 M -0.15 0.3 L0 0.5 L0.15 0.3", "transform" => "translate($(j-0.5) $(i-0.5)) rotate($(-rotate-90))")
    style = Dict("stroke" => "$colour", "stroke-width" => 0.1)
    add_svg_element(element_id, canvas_id, "path", i, j, attr = attr, style = style)
end
function add_pixel_arrow(canvas_id::String, i::Int, j::Int, rotate::Real = 0, colour::Any = "black")
    element_id = "pixel_arrow" * randstring(3)
    add_pixel_arrow(element_id, canvas_id, i, j, rotate, colour)
    return element_id
end
export add_pixel_arrow 

end