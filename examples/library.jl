
include("database.jl")
using Makie

@block SimonDanisch ["2d"] begin
    @cell "colored triangle" [mesh, polygon] begin
        scene = Scene(@resolution)
        # TODO: doesn't work
        # ERROR (unhandled task failure): glTexImage 2D: width too large. Width: 849439543
        # ERROR: can't splice Array{ColorTypes.RGBA{Float32},1} into an OpenGL shader. Make sure all fields are of a concrete type and isbits(FieldType)-->true
        mesh([(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)], color = [:red, :green, :blue], shading = false)
    end
    @cell "Subscenes" [image, scatter, subscene] begin

        # TODO: had to use Makie.loadasset
        img = rand(RGBAf0, 100, 100)
        scene = Scene(@resolution)
        # TODO: fails here with ERROR: MethodError: no method matching isless(::ColorTypes.RGBA{FixedPointNumbers.Normed{UInt8,8}}, ::ColorTypes.RGBA{FixedPointNumbers.Normed{UInt8,8}})
        is = image(img)
        center!(scene)
        # TODO: had to do Makie.Signal
        subscene = Scene(scene, Node(SimpleRectangle(0, 0, 200, 200)))
        scatter(subscene, rand(100) * 200, rand(100) * 200, markersize = 4)
        center!(scene)
        scene
    end

    @cell "Contour Function" [contour] begin
        # TODO: this works now with the latest changes from Simon and the AbstractPlotting.is2d temp fix
        scene = Scene(@resolution)
        r = linspace(-10, 10, 512)
        z = ((x, y)-> sin(x) + cos(y)).(r, r')
        contour!(scene, r, r, z, levels = 5, color = :RdYlBu)
    end


    @cell "Contour Simple" [contour] begin
        y = linspace(-0.997669, 0.997669, 23)
        contour(linspace(-0.99, 0.99, 23), y, rand(23, 23), levels = 10)
    end


    @cell "Heatmap" [heatmap] begin
        # TODO: it works, but Y Axis label is cut off through the bounding box (Simon knows this)
        heatmap(rand(32, 32))
    end

    @cell "Animated Scatter" [animation, scatter, updating] begin
        scene = Scene(@resolution)
        r = [(rand(7, 2) .- 0.5) .* 25 for i = 1:200]
        s = scatter(r[1][:, 1], r[1][:, 2], markersize = 1)
        #TODO make this work
        record(scene, @outpufile, r) do r
            s[:positions] = Point2f0.(view(r, :, 1), view(r, :, 2))
        end
    end

    @cell "Text Annotation" [text, align] begin
        # TODO: it works, but the plot appears very small, and only on the bottom-left corner.
        # TODO: Doing center! doesn't change zoom or its location.
        text(
            ". This is an annotation!",
            position = (300, 200),
            align = (:center,  :center),
            textsize = 60,
            font = "URW Chancery L"
        )
    end

    @cell "Text rotation" [text, rotation] begin
        # TODO: this works, but it works more reliably when you do scene = Scene(@resolution); scatter!(scene, posis, markersize = 10) (i.e. do it in one line vs multiple lines)
        using GeometryTypes
        scene = Scene(@resolution)
        pos = (500, 500)
        posis = Point2f0[]
        for r in linspace(0, 2pi, 20)
            p = pos .+ (sin(r)*100.0, cos(r) * 100)
            push!(posis, p)
            t = text!(
                scene, "test",
                position = p,
                textsize = 50,
                rotation = 1.5pi - r,
                align = (:center, :center)
            )
        end
        scatter!(scene, posis, markersize = 10)
    end
end

@block SimonDanisch ["3d"] begin


    @cell "Sample 7" [scatter, similar] begin
        scene = Scene(@resolution)
        # TODO: successfully plots, even though it ERROR (unhandled task failure): glTexImage 2D: width too large. Width: 849439543
        sv = scatter(rand(Point3f0, 100))
        # TODO: ERROR: function similar does not accept keyword arguments
        # Simon says: maybe we won't keep similar
        # similar(sv, rand(10), rand(10), rand(10), color = :black, markersize = 0.4)
    end

    @cell "Fluctuation 3D" [animated, mesh, meshscatter, axis] begin
        # TODO: this works, just had to add a lot of "Makie." to function handles
        # But no animation?
        scene = Scene(@resolution)
        # define points/edges
        perturbfactor = 4e1
        N = 3; nbfacese = 30; radius = 0.02
        # TODO: Need Makie.HyperSphere to work
        large_sphere = Makie.HyperSphere(Point3f0(0), 1f0)
        # TODO: Makie.decompose
        positions = Makie.decompose(Point3f0, large_sphere, 30)
        np = length(positions)
        pts = [positions[k][l] for k = 1:length(positions), l = 1:3]
        pts = vcat(pts, 1.1 * pts + randn(size(pts)) / perturbfactor) # light position influence ?
        edges = hcat(collect(1:np), collect(1:np) + np)
        ne = size(edges, 1); np = size(pts, 1)
        # define markers meshes
        meshC = GLNormalMesh(
            Makie.Cylinder{3, Float32}(
                Point3f0(0., 0., 0.),
                Point3f0(0., 0, 1.),
                Float32(1)
            ), nbfacese
        )
        meshS = GLNormalMesh(large_sphere, 20)
        # define colors, markersizes and rotations
        pG = [Point3f0(pts[k, 1], pts[k, 2], pts[k, 3]) for k = 1:np]
        lengthsC = sqrt.(sum((pts[edges[:,1], :] .- pts[edges[:, 2], :]) .^ 2, 2))
        sizesC = [Vec3f0(radius, radius, lengthsC[i]) for i = 1:ne]
        sizesC = [Vec3f0(1., 1., 1.) for i = 1:ne]
        colorsp = [Colors.RGBA{Float32}(rand(), rand(), rand(), 1.) for i = 1:np]
        colorsC = [(colorsp[edges[i, 1]] + colorsp[edges[i, 2]]) / 2. for i = 1:ne]
        sizesC = [Vec3f0(radius, radius, lengthsC[i]) for i = 1:ne]
        Qlist = zeros(ne, 4)
        for k = 1:ne
            ct = Makie.Cylinder{3, Float32}(
                Point3f0(pts[edges[k, 1], 1], pts[edges[k, 1], 2], pts[edges[k, 1], 3]),
                Point3f0(pts[edges[k, 2], 1], pts[edges[k, 2], 2], pts[edges[k, 2], 3]),
                Float32(1)
            )
            Q = GeometryTypes.rotation(ct)
            r = 0.5 * sqrt(1 + Q[1, 1] + Q[2, 2] + Q[3, 3]); Qlist[k, 4] = r
            Qlist[k, 1] = (Q[3, 2] - Q[2, 3]) / (4 * r)
            Qlist[k, 2] = (Q[1, 3] - Q[3, 1]) / (4 * r)
            Qlist[k, 3] = (Q[2, 1] - Q[1, 2]) / (4 * r)
        end
        rotationsC = [Makie.Vec4f0(Qlist[i, 1], Qlist[i, 2], Qlist[i, 3], Qlist[i, 4]) for i = 1:ne]
        # plot
        # TODO: again this only works if the Scene() command and the meshscatter! command are issued in the same line
        hm = meshscatter!(
            scene, pG[edges[:, 1]],
            color = colorsC, marker = meshC,
            markersize = sizesC,  rotations = rotationsC,
        )
        hp = meshscatter!(
            scene, pG,
            color = colorsp, marker = meshS, markersize = radius,
        )

    end

    @cell "Connected Sphere" [lines, views, scatter, axis] begin
        scene = Scene(@resolution)
        large_sphere = Makie.HyperSphere(Point3f0(0), 1f0)
        positions = Makie.decompose(Point3f0, large_sphere)
        linepos = view(positions, rand(1:length(positions), 1000))
        lines!(scene, linepos, linewidth = 0.1, color = :black)
        scatter!(scene, positions, strokewidth = 0.02, strokecolor = :white, color = RGBAf0(0.9, 0.2, 0.4, 0.6))
        scene
    end

    @cell "Simple meshscatter" [meshscatter] begin
        large_sphere = Sphere(Point3f0(0), 1f0)
        positions = decompose(Point3f0, large_sphere)
        meshscatter(positions, color = RGBAf0(0.9, 0.2, 0.4, 1))
    end

    @cell "Animated surface and wireframe" [wireframe, animated, surface, axis, video] begin
        # TODO: Doesn't work - see surf_func
        scene = Scene(@resolution)

        function xy_data(x, y)
            r = sqrt(x^2 + y^2)
            r == 0.0 ? 1f0 : (sin(r)/r)
        end

        r = linspace(1, 3, 40)
        surf_func(i) = [Float32(xy_data(x*i, y*i)) for x = r, y = r]
        # TODO: errors out here ERROR: DomainError:
        # Exponentiation yielding a complex result requires a complex argument.
        # Replace x^y with (x+0im)^y, Complex(x)^y, or similar.
        z = surf_func(20)
        surf = surface!(scene, r, r, z)[1]

        wf = wireframe!(scene, r, r, lift(x-> x .+ 1.0, surf[3]),
            linewidth = 2f0, color = lift(x-> to_colormap(x)[5], surf[:colormap])
        )
        scene
        # io = VideoStream(scene, @outputfile)
        for i in linspace(0, 60, 100)
            surf[3] = surf_func(i)
            sleep(1/60)
            AbstractPlotting.force_update!()
            # recordframe!(io)
        end
        # scene
    end

    @cell "Normals of a Cat" [mesh, linesegment, cat] begin
        scene = Scene(@resolution)
        x = Makie.loadasset("cat.obj")
        mesh!(scene, x.vertices, x.faces, color = :black)
        pos = map(x.vertices, x.normals) do p, n
            p => p .+ (normalize(n) .* 0.05f0)
        end
        linesegments!(scene, pos)
        scene
    end




    @cell "Sphere Mesh" [mesh] begin
        mesh(Sphere(Point3f0(0), 1f0), color = :blue)
    end


    @cell "Stars" [scatter, glow, update_cam!] begin
        using Makie, GeometryTypes
        stars = 100_000
        scene = Scene()
        scene.theme[:backgroundcolor] = RGBAf0(0, 0, 0, 1)
        scatter!(
            scene,
            (rand(Point3f0, stars) .- 0.5) .* 10,
            glowwidth = 0.005, glowcolor = :white, color = RGBAf0(0.8, 0.9, 0.95, 0.4),
            markersize = rand(linspace(0.0001, 0.01, 100), stars),
            show_axis = false
        )
        update_cam!(scene, FRect3D(Vec3f0(-2), Vec3f0(4)))
        scene
    end

    @cell "Unicode Marker" [scatter, axis, marker] begin
        scatter(Point3f0[(1,0,0), (0,1,0), (0,0,1)], marker = [:x, :circle, :cross])
    end

    @cell "Line Gif" [lines, animated, gif, offset] begin
        scene = Scene(@resolution)
        lineplots = []
        us = linspace(0, 1, 100)

        mktempdir() do path
            # TODO: ERROR: UndefVarError: @outputfile not defined
            io = VideoStream(scene, @outputfile)
            for i = 1:100
                if length(lineplots) < 20
                    push!(lineplots, lines(us, sin.(us .+ time()), zeros(100)))
                else
                    lineplots = circshift(lineplots, 1)
                    lp = first(lineplots)
                    lp[:positions] = Point3f0.(us, sin.(us .+ time()), zeros(100))
                    lp[:offset] = Vec3f0(0)
                end
                for lp in lineplots
                    z = to_value(lp, :offset)[3]
                    lp[:offset] = Vec3f0(0, 0, z + 0.1)
                end
                recordframe!(io)
            end
            finish(io, "gif")
        end
    end

    @cell "Complex Axis" [surface, axis, text] begin

        scene = Scene(@resolution)
        vx = -1:0.01:1;
        vy = -1:0.01:1;

        f(x, y) = (sin(x*10) + cos(y*10)) / 4
        # TODO: Error showing value of type AbstractPlotting.Scene:
        # ERROR: MethodError: no method matching to_range(::StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}})
        psurf = surface!(scene, vx, vy, f, show_axis = false)

        a = Makie.axis3d!(scene, linspace(extrema(vx)..., 4), linspace(extrema(vy)..., 4), linspace(-1, 1, 4))
        # TODO: ERROR: UndefVarError: center! not defined
        AbstractPlotting.center!(scene)

        # TODO: ERROR: KeyError: key :axisnames not found --> axis.jl line 310?
        # TODO: all of these keys are not defined
        a[:axisnames] = ("\\bf{ℜ}[u]", "\\bf{𝕴}[u]", " OK\n\\bf{δ}\n γ")
        a[:axisnames_size] = (0.15, 0.15, 0.15)
        a[:axisnames_color] = (:black, :black, :black)
        a[:axisnames_font] = "Palatino"

        # available_gradients() print gradients
        # TODO: ERROR: MethodError: no method matching setindex!(::AbstractPlotting.Scene, ::Symbol, ::Symbol)
        psurf[:colormap] = :RdYlBu
        # TODO: ERROR: UndefVarError: widths not defined
        wh = Makie.widths(scene)
        t = text(
            "Multipole Representation of first resonances of U-238",
            position = (wh[1] / 2.0, wh[2] - 20.0),
            align = (:center,  :center),
            textsize = 20,
            font = "Palatino",
            camera = :pixel
        )
        # TODO: ERROR: UndefVarError: Circle not defined -> had to use Makie.Circle
        # TODO: this gets plotted and replaces the surface plot from earlier -- probably not intended behaviour?
        c = lines(Makie.Circle(Point2f0(0.1, 0.5), 0.1f0), color = :red, offset = Vec3f0(0, 0, 1))
        #update surface
        # TODO: ERROR: MethodError: no method matching setindex!(::AbstractPlotting.Scene, ::Array{Float64,2}, ::Symbol)
        psurf[:z] = f.(vx .+ 0.5, (vy .+ 0.5)')
        scene
    end
end


@block SimonDanisch [documentation] begin
    @group begin

        @cell "Axis 2D" [axis] begin
            # TODO: not sure if it works - everything is black in the plot pane
            scene = Scene(@resolution)
            aviz = Makie.axis2d(linspace(0, 2, 4), linspace(0, 2, 4))
            AbstractPlotting.center!(scene)
        end

        @cell "Axis 3D" [axis] begin
            # TODO: not sure if it works - everything is black in the plot pane
            scene = Scene(@resolution)
            aviz = Makie.axis3d(linspace(0, 2, 4), linspace(0, 2, 4), linspace(0, 2, 4))
            AbstractPlotting.center!(scene)
        end

        @cell "Axis Custom" [axis] begin
            # always tuples of xyz for most attributes that are applied to each axis
            # TODO: ERROR: KeyError: key :gridcolors not found
            # TODO: ERROR: KeyError: key :axiscolors not found
            # TODO: aviz[:showticks] works
            aviz[:gridcolors] = (:gray, :gray, :gray)
            aviz[:axiscolors] = (:red, :black, :black)
            aviz[:showticks] = (true, true, false)
        end
    end

    @group begin
        @cell "overload to position" [axis] begin
            using GeometryTypes
            # To simplify the example, we take the already existing GeometryTypes.Circle type, which
            # can already be decomposed into positions
            function AbstractPlotting.convert_arguments(P, x::Circle)
                # Convert to a type to_positions can handle.
                # Everything that usually works in e.g. scatter/lines should be allowed here.
                positions = decompose(Point2f0, x, 50)
                # Pass your position data to to_positions,
                # just in case the backend has some extra converts
                # that are not visible in the user facing API.
                Makie.to_positions(backend, positions)
            end
            # TODO: lines() and scatter() seem to not add to the plot, but replace the previous plot?
            # TODO: I thought that would be the behaviour of the inplace functions
            p1 = lines!(Makie.Circle(Point2f0(0), 5f0))
            p2 = scatter!(Makie.Circle(Point2f0(0), 6f0))
            AbstractPlotting.center!(scene)
        end

        @cell "change size" [axis] begin
            # TODO: ERROR: MethodError: no method matching setindex!(::AbstractPlotting.Scene, ::GeometryTypes.HyperSphere{2,Float32}, ::Symbol)
            p2[:positions] = Makie.Circle(Point2f0(0), 7f0)
            AbstractPlotting.center!(scene)
        end
    end

    @cell "Volume Function" ["3d", volume] begin
        volume(rand(32, 32, 32), algorithm = :mip)
    end

    @cell "Heatmap Function" ["2d", heatmap] begin
        heatmap(rand(32, 32))
    end

    @cell "Textured Mesh" ["3d", mesh, texture, cat] begin
        cat = GeometryTypes.GLNormalUVMesh(Makie.loadasset("cat.obj"))
        # TODO: original: cat = load(assetpath("cat.obj"), GLNormalUVMesh)
        mesh(cat, color = Makie.loadasset("diffusemap.tga"))
    end
    @cell "Load Mesh" ["3d", mesh, cat] begin
        # TODO: this works
        scene = Scene(@resolution)
        mesh(Makie.loadasset("cat.obj"))
    end
    @cell "Colored Mesh" ["3d", mesh, axis] begin

        x = [0, 1, 2, 0]
        y = [0, 0, 1, 2]
        z = [0, 2, 0, 1]
        color = [:red, :green, :blue, :yellow]
        i = [0, 0, 0, 1]
        j = [1, 2, 3, 2]
        k = [2, 3, 1, 3]

        indices = [1, 2, 3, 1, 3, 4, 1, 4, 2, 2, 3, 4]
        # TODO:
        # ERROR: MethodError: no method matching GeometryTypes.HomogenousMesh{GeometryTypes.Point{3,Float32},GeometryTypes.Face{3,GeometryTypes.OffsetInteger{-1,UInt32}},GeometryTypes.Normal{3,Float32},Void,Void,Void,Void}(::Array{GeometryTypes.Point{3,Float32},1}, ::Array{Int64,1})
        mesh(x, y, z, indices, color = color)
    end
    @cell "Wireframe of a Mesh" ["3d", mesh, wireframe, cat] begin
        wireframe(Makie.loadasset("cat.obj"))
    end
    @cell "Wireframe of Sphere" ["3d", wireframe] begin
        wireframe(Sphere(Point3f0(0), 1f0))
    end
    @cell "Wireframe of a Surface" ["3d", surface, wireframe] begin
        function xy_data(x, y)
            r = sqrt(x^2 + y^2)
            r == 0.0 ? 1f0 : (sin(r)/r)
        end
        N = 30
        lspace = linspace(-10, 10, N)
        # TODO: ERROR: DomainError: (it doesn't say anything here)
        z = Float32[xy_data(x, y) for x in lspace, y in lspace]
        range = linspace(0, 3, N)
        wireframe(range, range, z)
    end
    @cell "Surface Function" ["3d", surface] begin
        # TODO: didn't work -> see later comments
        scene = Scene(@resolution)
        N = 32
        function xy_data(x, y)
            r = sqrt(x^2 + y^2)
            r == 0.0 ? 1f0 : (sin(r)/r)
        end
        lspace = linspace(-10, 10, 32)
        # TODO: ERROR: DomainError: (it doesn't say anything here)
        z = Float32[xy_data(x, y) for x in lspace, y in lspace]
        range = linspace(0, 3, N)
        surf = surface(range, range, z, colormap = :Spectral)
        AbstractPlotting.center!(scene)
    end
    @cell "Surface with image" ["3d", surface, image] begin
        function xy_data(x, y)
            r = sqrt(x^2 + y^2)
            r == 0.0 ? 1f0 : (sin(r)/r)
        end
        r = linspace(-2, 2, 30)
        surf_func(i) = [Float32(xy_data(x*i, y*i)) for x = r, y = r]
        surface(
            r, r, surf_func(10),
            image = rand(RGBAf0, 124, 124)
        )
    end
    @cell "Line Function" ["2d", lines] begin
        x = linspace(0, 3pi)
        lines(x, sin.(x))
    end

    @cell "Meshscatter Function" ["3d", meshscatter] begin
        # TODO: this works
        scene = Scene(@resolution)
        large_sphere = Sphere(Point3f0(0), 1f0)
        positions = GeometryTypes.decompose(Point3f0, large_sphere)
        colS = [RGBAf0(rand(), rand(), rand(), 1.0) for i = 1:length(positions)]
        sizesS = [rand(Point3f0) .* 0.5f0 for i = 1:length(positions)]
        meshscatter(positions, color = colS, markersize = sizesS)
    end

    @cell "Scatter Function" ["2d", scatter] begin
        # TODO: this works
        scatter(rand(20), rand(20))
    end

    @cell "Interaction" ["2d", scatter, linesegment, VideoStream] begin
        scene = Scene(@resolution)

        f(t, v, s) = (sin(v + t) * s, cos(v + t) * s)
        time = Node(0.0)
        p1 = scatter!(scene, lift(t-> f.(t, linspace(0, 2pi, 50), 1), time))[1]
        p2 = scatter!(scene, lift(t-> f.(t * 2.0, linspace(0, 2pi, 50), 1.5), time))[end]
        center!(scene)
        lines = lift(p1[1], p2[1]) do pos1, pos2
            map((a, b)-> (a, b), pos1, pos2)
        end
        linesegments!(scene, lines)

        AbstractPlotting.center!(scene)
        io = VideoStream(scene, @outputfile)
        # record a video
        for i = linspace(0, 10, 300)
            push!(time, i)
            sleep(1/60)
            AbstractPlotting.force_update!()
            #recordframe!(io)
        end
        io
    end
    @cell "Legend" ["3d", legend, lines, linestyle, scatter] begin
        scene = Scene(@resolution)
        # TODO: ERROR: UndefVarError: linesegment not defined
        plots = map([:dot, :dash, :dashdot], [2, 3, 4]) do ls, lw
            linesegments!(linspace(1, 5, 100), rand(100), rand(100), linestyle = ls, linewidth = lw)
        end

        # TODO: ERROR: MethodError: no method matching push!(::AbstractPlotting.#plots, ::AbstractPlotting.Scene)
        push!(plots, scatter!(linspace(1, 5, 100), rand(100), rand(100)))

        AbstractPlotting.center!(scene)

        # plot a legend for the plots with an array of names
        l = Makie.legend(plots, ["attribute $i" for i in 1:4])

        ann = VideoAnnotation(scene, @outputfile, "Themes")

        io = ann
        # TODO: ERROR: UndefVarError: recordstep! not defined
        recordstep!(io, "Interact with Legend:")
        # Change some attributes interactively
        l[:position] = (0.4, 0.7)
        recordstep!(io, "Change Position")
        l[:backgroundcolor] = RGBA(0.95, 0.95, 0.95)
        recordstep!(io, "Change Background")
        l[:strokecolor] = RGB(0.8, 0.8, 0.8)
        recordstep!(io, "Change Stroke Color")
        l[:gap] = 30
        recordstep!(io, "Change Gaps")
        l[:textsize] = 19
        recordstep!(io, "Change Textsize")
        l[:linepattern] = Point2f0[(0,-0.2), (0.5, 0.2), (0.5, 0.2), (1.0, -0.2)]
        recordstep!(io, "Change Line Pattern")
        l[:scatterpattern] = decompose(Point2f0, Circle(Point2f0(0.5, 0), 0.3f0), 9)
        recordstep!(io, "Change Scatter Pattern")
        l[:markersize] = 2f0
        recordstep!(io, "Change Marker Size")
        io
    end

    @cell "Color Legend" ["2d", colorlegend, legend] begin
        scene = Scene(@resolution)
        cmap = collect(linspace(to_color(:red), to_color(:blue), 20))
        # TODO: ERROR: MethodError: no method matching (::AbstractPlotting.##384#385{AbstractPlotting.Scene})(::AbstractPlotting.Scene)
        l = Makie.legend(cmap, 1:4)
        ann = VideoAnnotation(scene, @outputfile, "Color Map Legend:")
        recordstep!(io, "Color Map Legend:", 3)
        l[:position] = (1.0, 1.0)
        recordstep!(io, "Change Position")
        l[:textcolor] = :blue
        l[:strokecolor] = :black
        recordstep!(io, "Change Colors")
        l[:strokewidth] = 1
        l[:textsize] = 15
        l[:textgap] = 5
        recordstep!(io, "Change everything!")
        ann
    end

    @cell "VideoStream" ["3d", VideoStream, meshscatter, linesegment] begin
        # TODO: didn't work
        scene = Scene(@resolution)

        f(t, v, s) = (sin(v + t) * s, cos(v + t) * s, (cos(v + t) + sin(v)) * s)
        # TODO: ERROR: UndefVarError: to_node not defined
        t = Node(Base.time()) # create a life signal
        p1 = meshscatter!(scene, lift(t-> f.(t, linspace(0, 2pi, 50), 1), t))[1]
        p2 = meshscatter!(scene, lift(t-> f.(t * 2.0, linspace(0, 2pi, 50), 1.5), t))[end]

        # you can now reference to life attributes from the above plots:
        # TODO: ERROR: UndefVarError: lift_node not defined
        lines = lift(p1[1], p2[1]) do pos1, pos2
            map((a, b)-> (a, b), pos1, pos2)
        end

        linesegments!(scene, lines, linestyle = :dot)
        display(Makie.global_gl_screen(), scene)
        # record a video
        io = VideoStream(scene, @outputfile)
        for i = 1:300
            push!(t, Base.time())
            sleep(1/30)
            AbstractPlotting.force_update!()
            #recordframe!(io)
        end
        finish(io, "mp4") # could also be gif, webm or mkv
    end


    @group begin
        @cell "Theming Step 1" ["3d", scatter, surface] begin
            scene = Scene()
            vx = -1:0.1:1;
            vy = -1:0.1:1;
            f(x, y) = (sin(x*10) + cos(y*10)) / 4
            psurf = surface!(vx, vy, f)[1]

            # TODO: ERROR: MethodError: no method matching getindex(::AbstractPlotting.Scene, ::Symbol)
            pos = lift(psurf[1], psurf[2], psurf[3]) do x, y, z
                vec(Point3f0.(x, y', z .+ 0.5))
            end
            pscat = scatter!(pos)
            plines = lines!(lift(view, pos, lift(x->1:2:length(x), pos)))
        end

        @cell "Theming Step 2" ["3d", scatter, surface] begin
            # TODO: didn't work
            @theme theme = begin
                # TODO: ERROR: UndefVarError: to_markersize2d not defined
                markersize = to_markersize2d(0.01)
                strokecolor = to_color(:white)
                # TODO: ERROR: UndefVarError: to_float not defined
                strokewidth = to_float(0.01)
            end
            # this pushes all the values from theme to the plot
            # TODO: ERROR: UndefVarError: theme not defined
            # --> I guess it is from the above @theme block?
            push!(pscat, theme)
            # Update the entire surface node with this
            scene[:scatter] = theme
            # Or permananently (to be more precise: just for this session) change the theme for scatter
            scene[:theme, :scatter] = theme
            scatter(lift_node(x-> x .+ (Point3f0(0, 0, 1),), pos)) # will now use new theme
            scene
        end

        @cell "Theming Step 3" ["3d", scatter, surface] begin
            # TODO: didn't work
            # Make a completely new theme
            function custom_theme(scene)
                @theme theme = begin
                    linewidth = to_float(3)
                    colormap = to_colormap(:RdPu)
                    scatter = begin
                        marker = to_spritemarker(Circle)
                        markersize = to_float(0.03)
                        strokecolor = to_color(:white)
                        strokewidth = to_float(0.01)
                        glowcolor = to_color(RGBA(0, 0, 0, 0.4))
                        glowwidth = to_float(0.1)
                    end
                end
                # update theme values
                scene[:theme] = theme
            end

            # apply it to the scene
            custom_theme(scene)

            # From now everything will be plotted with new theme
            psurf = surface(vx, 1:0.1:2, psurf[:z])
            AbstractPlotting.center!(scene)
        end
    end
    @cell "3D Volume Contour with slices" [volume, contour, heatmap, slices, "3d layout", layout] begin
        r = linspace(-2pi, 2pi, 100)
        # TODO: WARNING: Base.rest is deprecated, use Base.Iterators.rest instead.
        # likely near no file:0
        # TODO:
        # ERROR: MethodError: AbstractPlotting.convert_arguments(::Type{VolumeSlices{...}}, ::StepRangeLen{Flo
        # at64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}}, ::StepRangeLen{Float64,Base.TwicePr
        # ecision{Float64},Base.TwicePrecision{Float64}}, ::StepRangeLen{Float64,Base.TwicePrecision{Float64},
        # Base.TwicePrecision{Float64}}, ::##119#120) is ambiguous.
        Makie.volumeslices(r, r, r, (x, y, z)-> sin(x) + cos(y) + sin(z))
    end
    @cell "3d volume animation" [volume, animation, gui, slices, layout] begin
        # TODO: is this example unfinished?
        r = linspace(-2pi, 2pi, 100)
        psps = map(1:100) do i
            broadcast(r, reshape(r, (1, 100, 1)), reshape(r, (1, 1, 100))) do x, y, z
                j = (i/100)
                sin(x * j) + cos(y * j) + sin(z)
            end
        end
    end
end

database