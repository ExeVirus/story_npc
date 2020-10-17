local viewer = {}

function viewer.viewObj(objfile)
    local export = io.open("obj.html", "w+") --Open file for writing
    io.output(export)

    local plotly_header = require "./plotly_header" --Get the shared html header
    io.write(plotly_header)

    io.write("<script>\n")
    io.write("var data = [{ \n")
    io.write('type: "mesh3d",\n')
    --Write the X's
    io.write('x: [')
    for i,v in ipairs(objfile.v) do
        io.write(v.x .. ", ")
    end
    io.write('],\n');
    --Write the Y's
    io.write('y: [')
    for i,v in ipairs(objfile.v) do
        io.write(v.y .. ", ")
    end
    io.write('],\n');
    --Write the Z's
    io.write('z: [')
    for i,v in ipairs(objfile.v) do
        io.write(v.z .. ", ")
    end
    io.write('],\n');
    --Write the I's
    io.write('i: [')
    for i,v in ipairs(objfile.f) do
        io.write(v[1]-1 .. ", ")
    end
    io.write('],\n');
    --Write the J's
    io.write('j: [')
    for i,v in ipairs(objfile.f) do
        io.write(v[2]-1 .. ", ")
    end
    io.write('],\n');
    --Write the K's
    io.write('k: [')
    for i,v in ipairs(objfile.f) do
        io.write(v[3]-1 .. ", ")
    end
    io.write('],\n');

    io.write([[
        opacity:0.2,
        color:'rgb(200,100,300)',
    }];
    Plotly.newPlot('myDiv', data);
    </script>
    ]])
    print("wrote Obj.html\n")
    io.close(export)
end

--
-- Function view_result(grid) -- Shows the filled verticies from voxelize
--
function viewer.view_grid(grid)
	local output = ""--String for plotly
	--strings for x's, y's, z's :)
	local xs = "x: ["
	local ys = "y: ["
	local zs = "z: ["
	for i, v in ipairs(grid.voxel_verts) do
		xs = xs .. v.x .. ", "
		ys = ys .. v.y .. ", "
		zs = zs .. v.z .. ", "
	end
	xs = xs .. "],\n"
	ys = ys .. "],\n"
	zs = zs .. "],\n"

	output = output .. "var grid = {\n"
	output = output .. xs
	output = output .. ys
	output = output .. zs
	output = output .. "mode: 'markers',\n"
	output = output .. "marker: { size: 2},\n"
	output = output .. "name: 'grid',\n"
	output = output .. "type: 'scatter3d',\n}\n"
	return output
end

function viewer.viewObjGrid(objfile, grid)
    local export = io.open("ObjGrid.html", "w+")
    io.output(export)

    local plotly_header = require "./plotly_header"
    io.write(plotly_header)

    io.write("<script>\n")
    io.write(viewer.view_grid(grid))
    io.write("var data = [{ \n")
    io.write('type: "mesh3d",\n')
    --Write the X's
    io.write('x: [')
    for i,v in ipairs(objfile.v) do
        io.write(v.x .. ", ")
    end
    io.write('],\n');
    --Write the Y's
    io.write('y: [')
    for i,v in ipairs(objfile.v) do
        io.write(v.y .. ", ")
    end
    io.write('],\n');
    --Write the Z's
    io.write('z: [')
    for i,v in ipairs(objfile.v) do
        io.write(v.z .. ", ")
    end
    io.write('],\n');
    --Write the I's
    io.write('i: [')
    for i,v in ipairs(objfile.f) do
        io.write(v[1]-1 .. ", ")
    end
    io.write('],\n');
    --Write the J's
    io.write('j: [')
    for i,v in ipairs(objfile.f) do
        io.write(v[2]-1 .. ", ")
    end
    io.write('],\n');
    --Write the K's
    io.write('k: [')
    for i,v in ipairs(objfile.f) do
        io.write(v[3]-1 .. ", ")
    end
    io.write('],\n');

    io.write([[
        opacity:0.2,
        color:'rgb(200,100,300)',
        name: 'obj',
        showlegend: true,
    }, grid];

    var layout = {
      autosize: false,
      width: 1200,
      height: 1000,
      margin: {
        l: 200,
        r: 0,
        b: 0,
        t: 0,
        pad: 4
      },
      showlegend: true,
      legend: {
        x: 1,
        y: 0.5,
       },
        scene:{
            aspectmode: "manual",
            aspectratio: {
                x: 1, y: 1, z: 1,
            },         ]])

    --Find the largest dimension:
    local MaxDim = math.max(grid.dimensions.x, grid.dimensions.y, grid.dimensions.z)
    io.write("xaxis: {nticks: 10,range: [" .. grid.offset.x-0.001 .. ", " .. grid.offset.x+MaxDim .. "],},")
    io.write("yaxis: {nticks: 10,range: [" .. grid.offset.y-0.001 .. ", " .. grid.offset.y+MaxDim .. "],},")
    io.write("zaxis: {nticks: 10,range: [" .. grid.offset.z-0.001 .. ", " .. grid.offset.z+MaxDim .. "],},")
    io.write([[
    },
    };

    Plotly.newPlot('myDiv', data, layout);
    </script>
    ]])

    io.close(export)
end

--
--Function view_subdivided_grid(grid,name) exports a single scatter plot of a broken up grid from break_Up
--
--name is the name on the html file you will see
function viewer.view_subdivided_grid(grid,name)
	local output = ""--String for plotly
	--strings for x's, y's, z's :)
	local xs = "x: ["
	local ys = "y: ["
	local zs = "z: ["

	local xGridLength = grid.lengths.x
	local yGridLength = grid.lengths.y
	local zGridLength = grid.lengths.z

	for i = 0, xGridLength-1, 1 do
		for j = 0, yGridLength-1, 1 do
			for k = 1, zGridLength, 1 do
				index = k + j * zGridLength + i * yGridLength * zGridLength--re-doing our array reference :)
				if grid.voxels[index] == 1 then
					xs = xs .. grid.offset.x + grid.position.x + i * grid.spacing .. ", "
					ys = ys .. grid.offset.y + grid.position.y + j * grid.spacing .. ", "
					zs = zs .. grid.offset.z + grid.position.z + (k-1) * grid.spacing .. ", "
				end
			end
		end
	end
	xs = xs .. "],\n"
	ys = ys .. "],\n"
	zs = zs .. "],\n"

	output = output .. "var " .. name .. " = {\n"
	output = output .. xs
	output = output .. ys
	output = output .. zs
	output = output .. "mode: 'markers',\n"
	output = output .. "marker: { size: 2},\n"
	output = output .. "name: '" .. name .. "',\n"
	output = output .. "type: 'scatter3d',\n}\n"
	return output
end

function viewer.viewObjSubGrid(objfile, grid, groups)
    local export = io.open("ObjSubGrids.html", "w+")
    io.output(export)

    local plotly_header = require "./plotly_header"
    io.write(plotly_header)

    io.write("<script>\n")
    io.write(viewer.view_grid(grid))
    --Export all the resulting grids
    for i = 1, groups.size.x*groups.size.y*groups.size.z, 1 do
        io.write(viewer.view_subdivided_grid(groups.grid[i], "grid" .. i))
    end
    io.write("var data = [{ \n")
    io.write('type: "mesh3d",\n')
    --Write the X's
    io.write('x: [')
    for i,v in ipairs(objfile.v) do
        io.write(v.x .. ", ")
    end
    io.write('],\n');
    --Write the Y's
    io.write('y: [')
    for i,v in ipairs(objfile.v) do
        io.write(v.y .. ", ")
    end
    io.write('],\n');
    --Write the Z's
    io.write('z: [')
    for i,v in ipairs(objfile.v) do
        io.write(v.z .. ", ")
    end
    io.write('],\n');
    --Write the I's
    io.write('i: [')
    for i,v in ipairs(objfile.f) do
        io.write(v[1]-1 .. ", ")
    end
    io.write('],\n');
    --Write the J's
    io.write('j: [')
    for i,v in ipairs(objfile.f) do
        io.write(v[2]-1 .. ", ")
    end
    io.write('],\n');
    --Write the K's
    io.write('k: [')
    for i,v in ipairs(objfile.f) do
        io.write(v[3]-1 .. ", ")
    end
    io.write('],\n');

    io.write([[
        opacity:0.2,
        color:'rgb(200,100,300)',
        name: 'obj',
        showlegend: true,
    }, grid
    ]])

    --include the many broken up grids
    for i = 1, groups.size.x*groups.size.y*groups.size.z, 1 do
        io.write(", grid"..i)
    end
    io.write("];")--end the block

    io.write([[
    var layout = {
      autosize: false,
      width: 1200,
      height: 1000,
      margin: {
        l: 200,
        r: 0,
        b: 0,
        t: 0,
        pad: 4
      },
      showlegend: true,
      legend: {
        x: 1,
        y: 0.5,
       },
       scene:{
            aspectmode: "manual",
            aspectratio: {
                x: 1, y: 1, z: 1,
            },         ]])

    --Find the largest dimension:
    local MaxDim = math.max(grid.dimensions.x, grid.dimensions.y, grid.dimensions.z)
    io.write("xaxis: {nticks: 10,range: [" .. grid.offset.x-0.001 .. ", " .. grid.offset.x+MaxDim .. "],},")
    io.write("yaxis: {nticks: 10,range: [" .. grid.offset.y-0.001 .. ", " .. grid.offset.y+MaxDim .. "],},")
    io.write("zaxis: {nticks: 10,range: [" .. grid.offset.z-0.001 .. ", " .. grid.offset.z+MaxDim .. "],},")
    io.write([[
    },
    };

    Plotly.newPlot('myDiv', data, layout);
    </script>
    ]])

    io.close(export)
end


--
--Function view_boxes(box,offset,spacing,name) exports a single box plot from boxify
--
--name is the name on the html file you will see
function viewer.view_box(box,offset,spacing,name, color)
	local output = ""--String for plotly
	--strings for x's, y's, z's :)
	local start = box.start
	local fin = box.fin
	start.x = offset.x + (start.x-1) * spacing
	start.y = offset.y + (start.y-1) * spacing
	start.z = offset.z + (start.z-1) * spacing
	fin.x = offset.x + (fin.x-1) * spacing
	fin.y = offset.y + (fin.y-1) * spacing
	fin.z = offset.z + (fin.z-1) * spacing

	local xs = "x: ["
	local ys = "y: ["
	local zs = "z: ["
	xs = xs .. start.x .. ", " .. start.x .. ", " .. fin.x .. ", " .. fin.x .. ", " .. start.x .. ", " .. start.x .. ", " .. fin.x .. ", " .. fin.x .. ", "
	ys = ys .. start.y .. ", " .. fin.y .. ", " .. fin.y .. ", " .. start.y .. ", " .. start.y .. ", " .. fin.y .. ", " .. fin.y .. ", " .. start.y .. ", "
	zs = zs .. start.z .. ", " .. start.z .. ", " .. start.z .. ", " .. start.z .. ", " .. fin.z .. ", " .. fin.z .. ", " .. fin.z .. ", " .. fin.z .. ", "
	xs = xs .. "],\n"
	ys = ys .. "],\n"
	zs = zs .. "],\n"
	--Create output var
	output = output .. "var " .. name .. " = {\n"
	output = output .. xs
	output = output .. ys
	output = output .. zs
	output = output .. "i: [7, 0, 0, 0, 4, 4, 6, 6, 4, 0, 3, 2],\n"
    output = output .. "j: [3, 4, 1, 2, 5, 6, 5, 2, 0, 1, 6, 3],\n"
    output = output .. "k: [0, 7, 2, 3, 6, 7, 1, 1, 5, 5, 7, 6],\n"
	output = output .. "opacity: 0.2, \n"
	output = output .. "color:".. color ..",\n"
	output = output .. "name: '" .. name .. "',\n"
	output = output .. "showlegend: true,\n"
	output = output .. "type: 'mesh3d',\n}\n"
	return output
end

function viewer.viewObjBoxes(objfile, grid, boxGroups)
	local colors = {}
	colors[1] = "'rgb(100,100,100)'"
	colors[2] = "'rgb(175,75,75)'"
	colors[3] = "'rgb(75,175,75)'"
	colors[4] = "'rgb(75,75,175)'"
	colors[5] = "'rgb(135,135,50)'"
	colors[6] = "'rgb(135,50,135)'"
	colors[7] = "'rgb(50,135,135)'"


    local export = io.open("Boxes.html", "w+")
    io.output(export)

    local plotly_header = require "./plotly_header"
    io.write(plotly_header)

    io.write("<script>\n")
    io.write(viewer.view_grid(grid))
    --Export all the resulting boxes
    for i = 1, boxGroups.size.x*boxGroups.size.y*boxGroups.size.z, 1 do
        for j = 1, boxGroups[i].numBoxes, 1 do
            io.write(viewer.view_box(boxGroups[i].boxes[j], boxGroups[i].offset, boxGroups.spacing, "set" .. i .."box" .. j, colors[((i-1) % 7)+1]))
        end
    end
    io.write("var data = [{ \n")
    io.write('type: "mesh3d",\n')
    --Write the X's
    io.write('x: [')
    for i,v in ipairs(objfile.v) do
        io.write(v.x .. ", ")
    end
    io.write('],\n');
    --Write the Y's
    io.write('y: [')
    for i,v in ipairs(objfile.v) do
        io.write(v.y .. ", ")
    end
    io.write('],\n');
    --Write the Z's
    io.write('z: [')
    for i,v in ipairs(objfile.v) do
        io.write(v.z .. ", ")
    end
    io.write('],\n');
    --Write the I's
    io.write('i: [')
    for i,v in ipairs(objfile.f) do
        io.write(v[1]-1 .. ", ")
    end
    io.write('],\n');
    --Write the J's
    io.write('j: [')
    for i,v in ipairs(objfile.f) do
        io.write(v[2]-1 .. ", ")
    end
    io.write('],\n');
    --Write the K's
    io.write('k: [')
    for i,v in ipairs(objfile.f) do
        io.write(v[3]-1 .. ", ")
    end
    io.write('],\n');

    io.write([[
        opacity:0.2,
        color:'rgb(200,100,300)',
        name: 'obj',
        showlegend: true,
    }, grid
    ]])

    for i = 1, boxGroups.size.x*boxGroups.size.y*boxGroups.size.z, 1 do
        for j = 1, boxGroups[i].numBoxes, 1 do
            io.write(", set" .. i.."box" .. j)
        end
    end
    io.write("];")--end the block

    io.write([[
    var layout = {
        autosize: false,
        width: 1200,
        height: 1000,
        margin: {
            l: 200,
            r: 0,
            b: 0,
            t: 0,
            pad: 4
        },
        showlegend: true,
        legend: {
            x: 1,
            y: 0.5,
        },
        scene:{
            aspectmode: "manual",
            aspectratio: {
                x: 1, y: 1, z: 1,
            },         ]])

    --Find the largest dimension:
    local MaxDim = math.max(grid.dimensions.x, grid.dimensions.y, grid.dimensions.z)
    io.write("xaxis: {nticks: 10,range: [" .. grid.offset.x-0.001 .. ", " .. grid.offset.x+MaxDim .. "],},")
    io.write("yaxis: {nticks: 10,range: [" .. grid.offset.y-0.001 .. ", " .. grid.offset.y+MaxDim .. "],},")
    io.write("zaxis: {nticks: 10,range: [" .. grid.offset.z-0.001 .. ", " .. grid.offset.z+MaxDim .. "],},")
    io.write([[
    },
    };

    Plotly.newPlot('myDiv', data, layout);
    </script>
    ]])

    io.close(export)
end





return viewer
