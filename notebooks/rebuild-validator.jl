### A Pluto.jl notebook ###
# v0.14.6

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 766e600d-200c-4421-9a21-a8fa0aa6a4a7
begin
	import Pkg
	Pkg.activate(".")
	Pkg.instantiate()	
	using PlutoUI
	using CitableText
	using CitableObject
	using CitableImage
	using CitableTeiReaders
	using CSV
	using DataFrames
	using EditionBuilders
	using EditorsRepo
	using HTTP
	#using Lycian
	using Markdown
	using Orthography
	using PolytonicGreek
	Pkg.status()
end


# ╔═╡ ee621b58-bda9-11eb-2a89-5565dab91b23
md">Validator : experimental version of nb"

# ╔═╡ 617ce64a-d7b1-4f66-8bd0-f7a240a929a7
@bind loadem Button("Load/reload data")

# ╔═╡ 8cd70daf-566d-423d-931c-e5021ad2778a
begin
	loadem
	nbversion = Pkg.TOML.parse(read("Project.toml", String))["version"]
	md"""
	## Validating notebook
	
	- References for editors:  see the [2021 summer experience reference sheet](https://homermultitext.github.io/hmt-se2021/references/)
	- Version: this is version **$(nbversion)** of the MID validation notebook.
	
	
	
	"""
end

# ╔═╡ 17ebe116-0d7f-4051-a548-1573121a33c9
begin
	loadem
	github = Pkg.TOML.parse(read("MID.toml", String))["github"]
	projectname =	Pkg.TOML.parse(read("MID.toml", String))["projectname"]

	pg = string(
		
		"<blockquote  class='splash'>",
		"<div class=\"center\">",
		"<h2>Project: <em>",
		projectname,
		"</em>",
		"</h2>",
		"</div>",
		"<ul>",
		"<li>On github at:  ",
		"<a href=\"" * github * "\">" * github * "</a>",
		"</li>",
		
		"<li>Repository cloned in: ",
		"<strong>",
		dirname(pwd()),
		"</strong>",
		"</li>",
		"</ul>",

		"</blockquote>"
		)
	
	HTML(pg)
	
end

# ╔═╡ ee2f04c1-42bb-46bb-a381-b12138e550ee
md"> ## Verification: DSE indexing"

# ╔═╡ 06bfa57d-2bbb-498e-b68e-2892d7186245
md"""
### Verify *accuracy* of indexing

*Check that diplomatic text and indexed image correspond.*


"""

# ╔═╡ ad541819-7d4f-4812-8476-8a307c5c1f87
md"""
*Maximum width of image*: $(@bind w Slider(200:1200, show_value=true))

"""

# ╔═╡ ea1b6e21-7625-4f8f-a345-8e96449c0757
md"""

---

---

"""

# ╔═╡ fe16419f-c83c-42b8-a56d-68ea0122efad
md"> #### Functions"

# ╔═╡ fd401bd7-38e5-44b5-8131-dbe5eb4fe41b
md"> Formatting"


# ╔═╡ 066b9181-9d41-4013-81b2-bcc37878ab68
# Format HTML for EditingRepository's reporting on cataloging status.
function catalogcheck(editorsrepo::EditingRepository)
	cites = citation_df(editorsrepo)
	if filesmatch(editorsrepo, cites)
		md"✅XML files in repository match catalog entries."
	else
		htmlstrings = []
		
		missingfiles = filesonly(editorsrepo, cites)
		if ! isempty(missingfiles)
			fileitems = map(f -> "<li>" * f * "</li>", missingfiles)
			filelist = "<p>Uncataloged files found on disk: </p><ul>" * join(fileitems,"\n") * "</ul>"
			
			hdr = "<div class='warn'><h1>⚠️ Warning</h1>"
			tail = "</div>"
			badfileshtml = join([hdr, filelist, tail],"\n")
			push!(htmlstrings, badfileshtml)
		end
		
		notondisk = citedonly(editorsrepo, cites)
		if ! isempty(notondisk)
			nofilelist = "<p>Configured files not found on disk: </p><ul>" * join(nofiletems, "\n") * "</ul>"
			hdr = "<div class='danger'><h1>🧨🧨 Configuration error 🧨🧨 </h1>" 
			tail = "</div>"
			nofilehtml = join([hdr, nofilelist, tail],"\n")
			push!(htmlstrings,nofilehtml)
		end
		HTML(join(htmlstrings,"\n"))
	end

end

# ╔═╡ 5cba9a9c-74cc-4363-a1ff-026b7b3999ea
#Create list of text labels for popupmenu
function surfacemenu(editorsrepo)
	loadem
	surfurns = EditorsRepo.surfaces(editorsrepo)
	surflist = map(u -> u.urn, surfurns)
	# Add a blank entry so popup menu can come up without a selection
	pushfirst!( surflist, "")
end

# ╔═╡ 53634d1d-24c5-4fe3-a7bf-ba8f6d569cfa
xrow = xsurfDse[1, :]

# ╔═╡ 987266ac-26b4-49b5-82ab-9719a63f6a3d
md"> Texts in the repository"

# ╔═╡ a771c143-01ca-45f8-a628-eaa66cb704a7
# True if last component of CTS URN passage is "ref".
# We use this to exclude elements with this identifier, 
# like HMT scholia
function isref(urn::CtsUrn)::Bool
    # True if last part of 
    passageparts(urn)[end] == "ref"
end

# ╔═╡ 32614e8a-6a69-48c3-ac02-2a6047ae711a
# Collect diplomatic text for a text passage identified by URN.
# The URN should either match a citable node, or be a containing node
# for one or more citable nodes.  Ranges URNs are not supported.
function diplnode(urn, repo)
	diplomaticpassages = repo |> EditorsRepo.diplpassages
	generalized = dropversion(urn)
	filtered = filter(cn -> urncontains(generalized, dropversion(cn.urn)), 		diplomaticpassages)
    dropref = filter(cn -> ! isref(cn.urn), filtered)
    
	if length(dropref) > 0
        content = collect(map(n -> n.text, dropref))
        join(content, "\n")
	else 
		""
	end
end

# ╔═╡ 8bf92039-8779-4fab-880b-f2ef58746103
# Collect diplomatic text for a text passage identified by URN.
# The URN should either match a citable node, or be a containing node
# for one or more citable nodes.  Ranges URNs are not supported.
function normednode(urn, repo)
	normalizedpassages = repo |> EditorsRepo.normedpassages
    generalized = dropversion(urn)
    filtered = filter(cn -> urncontains(generalized, dropversion(cn.urn)), normalizedpassages)
	#filtered = filter(cn -> generalized == dropversion(urn), normalizedpassages)
    dropref = filter(cn -> ! isref(cn.urn), filtered)
    
	if length(dropref) > 0
        content = collect(map(n -> n.text, dropref))
        join(content, "\n")
		#filtered[1].text
	else 
		""
	end
end

# ╔═╡ fe31ee7e-4d74-4c65-81e6-5bff0c1d2136
md"> New functions"

# ╔═╡ ec0f3c61-cf3b-4e4c-8419-176626a0888c
md"> Repository and image services"

# ╔═╡ 43734e4f-2efc-4f12-81ac-bce7bf7ada0a
# Create EditingRepository for this notebook's repository
# Since the notebook is in the `notebooks` subdirectory of the repository,
# we can just use the parent directory (dirname() in julia) for the
# root directory.
function editorsrepo() 
    EditingRepository( dirname(pwd()), "editions", "dse", "config")
end

# ╔═╡ 35255eb9-1f54-4f9d-8c58-2d450e09dff9
begin
	loadem
	editorsrepo() |> catalogcheck
end

# ╔═╡ 8d407e7a-1201-4dd3-bddd-368362037205
md"""###  Choose a surface to verify

$(@bind surface Select(surfacemenu(editorsrepo())))
"""

# ╔═╡ 080b744e-8f14-406d-bdd2-fbcd3c1ec753
# Base URL for an ImageCitationTool
function ict()
	"http://www.homermultitext.org/ict2/?"
end

# ╔═╡ 806b3733-6c06-4956-8b86-aa096f060ac6
# API to work with an IIIF image service
function iiifsvc()
	IIIFservice("http://www.homermultitext.org/iipsrv",
	"/project/homer/pyramidal/deepzoom")
end

# ╔═╡ 59fbd3de-ea0e-4b96-800c-d5d8a7272922
# Compose markdown for one row of display interleaving citable
# text passage and indexed image.
function mdForDseRow(row::DataFrameRow)
	citation = "**" * passagecomponent(row.passage)  * "** "

	
	txt = diplnode(row.passage, editorsrepo())
	caption = passagecomponent(row.passage)
	
	img = linkedMarkdownImage(ict(), row.image, iiifsvc(); ht=w, caption=caption)
	
	#urn
	record = """$(citation) $(txt)

$(img)

---
"""
	record
end

# ╔═╡ 2c0180ce-c611-4047-8143-aca609b9a4fa
imglink  = linkedMarkdownImage(ict(), xrow.image, iiifsvc(); ht=w, caption="caption")

# ╔═╡ a5ee0d67-60d3-42eb-b551-4463e7c50f2c
md"> DSE indexing"

# ╔═╡ 476c9ae2-0dd7-4603-b529-17c229d83f7e
# Find DSE records for surface currently selected in popup menu.
function surfaceDse(surfurn, repo)
    alldse = dse_df(editorsrepo())
	filter(row -> row.surface == surfurn, alldse)
end

# ╔═╡ 73839e47-8199-4755-8d55-362185907c45
# Display for visual validation of DSE indexing
begin

	if surface == ""
		md""
	else
		surfDse = surfaceDse(Cite2Urn(surface), editorsrepo())
		cellout = []
		
		try
			for r in eachrow(surfDse)
				push!(cellout, mdForDseRow(r))
			end

		catch e
			html"<p class='danger'>Problem with XML edition: see message below</p>"
		end
		Markdown.parse(join(cellout,"\n"))				
		
	end

end

# ╔═╡ Cell order:
# ╟─ee621b58-bda9-11eb-2a89-5565dab91b23
# ╟─8cd70daf-566d-423d-931c-e5021ad2778a
# ╟─766e600d-200c-4421-9a21-a8fa0aa6a4a7
# ╟─17ebe116-0d7f-4051-a548-1573121a33c9
# ╟─35255eb9-1f54-4f9d-8c58-2d450e09dff9
# ╟─617ce64a-d7b1-4f66-8bd0-f7a240a929a7
# ╟─8d407e7a-1201-4dd3-bddd-368362037205
# ╟─ee2f04c1-42bb-46bb-a381-b12138e550ee
# ╟─06bfa57d-2bbb-498e-b68e-2892d7186245
# ╟─ad541819-7d4f-4812-8476-8a307c5c1f87
# ╟─73839e47-8199-4755-8d55-362185907c45
# ╟─ea1b6e21-7625-4f8f-a345-8e96449c0757
# ╟─fe16419f-c83c-42b8-a56d-68ea0122efad
# ╟─fd401bd7-38e5-44b5-8131-dbe5eb4fe41b
# ╟─066b9181-9d41-4013-81b2-bcc37878ab68
# ╟─5cba9a9c-74cc-4363-a1ff-026b7b3999ea
# ╠═59fbd3de-ea0e-4b96-800c-d5d8a7272922
# ╠═53634d1d-24c5-4fe3-a7bf-ba8f6d569cfa
# ╠═2c0180ce-c611-4047-8143-aca609b9a4fa
# ╟─987266ac-26b4-49b5-82ab-9719a63f6a3d
# ╟─32614e8a-6a69-48c3-ac02-2a6047ae711a
# ╟─8bf92039-8779-4fab-880b-f2ef58746103
# ╟─a771c143-01ca-45f8-a628-eaa66cb704a7
# ╟─fe31ee7e-4d74-4c65-81e6-5bff0c1d2136
# ╟─ec0f3c61-cf3b-4e4c-8419-176626a0888c
# ╟─43734e4f-2efc-4f12-81ac-bce7bf7ada0a
# ╟─080b744e-8f14-406d-bdd2-fbcd3c1ec753
# ╟─806b3733-6c06-4956-8b86-aa096f060ac6
# ╟─a5ee0d67-60d3-42eb-b551-4463e7c50f2c
# ╟─476c9ae2-0dd7-4603-b529-17c229d83f7e
