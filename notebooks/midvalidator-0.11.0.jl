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


# ╔═╡ 617ce64a-d7b1-4f66-8bd0-f7a240a929a7
@bind loadem Button("Load/reload data")

# ╔═╡ 8cd70daf-566d-423d-931c-e5021ad2778a
begin
	loadem
	nbversion = Pkg.TOML.parse(read("Project.toml", String))["version"]
	md"""## Validating notebook: version *$(nbversion)*

References for editors:  see the [2021 summer experience reference sheet](https://homermultitext.github.io/hmt-se2021/references/)
	
	
	
	
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

# ╔═╡ 834a67df-8c8b-47c6-aa3e-20297576019a
md"""

### Verify *completeness* of indexing


*Check completeness of indexing by following linked thumb to overlay view in the Image Citation Tool*
"""

# ╔═╡ 8fcf792e-71eb-48d9-b0e6-e7e175628ccd
md"*Height of thumbnail image*: $(@bind thumbht Slider(150:500, show_value=true))"


# ╔═╡ 06bfa57d-2bbb-498e-b68e-2892d7186245
md"""
### Verify *accuracy* of indexing

*Check that diplomatic text and indexed image correspond.*


"""

# ╔═╡ ad541819-7d4f-4812-8476-8a307c5c1f87
md"""
*Maximum width of image*: $(@bind w Slider(200:1200, show_value=true))

"""

# ╔═╡ 3dd88640-e31f-4400-9c34-2adc2cd4c532
md"""

> ## Verification:  orthography

"""

# ╔═╡ ea1b6e21-7625-4f8f-a345-8e96449c0757
md"""

---

---


> ### Functions

You don't need to look at the rest of the notebook unless you're curious about how it works.  The following cells define the functions that retreive data from your editing repository, validate it, and format it for visual verification.

"""

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

# ╔═╡ 1814e3b1-8711-4afd-9987-a41d85fd56d9
# Wrap tokens with invalid orthography in HTML tag
function formatToken(ortho, s)
	
	if validstring(ortho, s)
			s
	else
		"""<span class='invalid'>$(s)</span>"""
	end
end

# ╔═╡ 3dd9b96b-8bca-4d5d-98dc-a54e00c75030
css = html"""
<style>
.splash {
	background-color: #f0f7fb;
}
.danger {
     background-color: #fbf0f0;
     border-left: solid 4px #db3434;
     line-height: 18px;
     overflow: hidden;
     padding: 15px 60px;
   font-style: normal;
	  }
.warn {
     background-color: 	#ffeeab;
     border-left: solid 4px  black;
     line-height: 18px;
     overflow: hidden;
     padding: 15px 60px;
   font-style: normal;
  }

  .danger h1 {
	color: red;
	}

 .invalid {
	text-decoration-line: underline;
  	text-decoration-style: wavy;
  	text-decoration-color: red;
}
 .center {
text-align: center;
}
.highlight {
  background: yellow;  
}
.urn {
	color: silver;
}
  .note { -moz-border-radius: 6px;
     -webkit-border-radius: 6px;
     background-color: #eee;
     background-image: url(../Images/icons/Pencil-48.png);
     background-position: 9px 0px;
     background-repeat: no-repeat;
     border: solid 1px black;
     border-radius: 6px;
     line-height: 18px;
     overflow: hidden;
     padding: 15px 60px;
    font-style: italic;
 }


.instructions {
     background-color: #f0f7fb;
     border-left: solid 4px  #3498db;
     line-height: 18px;
     overflow: hidden;
     padding: 15px 60px;
   font-style: normal;
  }



</style>
"""

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

# ╔═╡ 71d7a180-5742-415c-9013-d3d1c0ca920c

# Compose markdown for thumbnail images linked to ICT with overlay of all
# DSE regions.
function completenessView(urn, repo)
     
	# Group images with ROI into a dictionary keyed by image
	# WITHOUT RoI.
	grouped = Dict()
	for row in eachrow(surfaceDse(urn, repo))
		trimmed = CitableObject.dropsubref(row.image)
		if haskey(grouped, trimmed)
			push!(grouped[trimmed], row.image)
		else
			grouped[trimmed] = [row.image]
		end
	end

	mdstrings = []
	for k in keys(grouped)
		thumb = markdownImage(k, iiifsvc(), thumbht)
		params = map(img -> "urn=" * img.urn * "&", grouped[k]) 
		lnk = ict() * join(params,"") 
		push!(mdstrings, "[$(thumb)]($(lnk))")
		
	end
	join(mdstrings, " ")

end

# ╔═╡ 9e6f8bf9-4aa7-4253-ba3f-695b13ca6def
# Display link for completeness view
begin
	if isempty(surface)
		md""
	else
		Markdown.parse(completenessView(Cite2Urn(surface), editorsrepo()))
	end
end

# ╔═╡ 9913000f-295a-41e3-bdfa-003774d3f574
# Find URN for a single node from DSE record, which could
# include a range with subrefs within a single node.
function baseurn(urn::CtsUrn)
	trimmed = CitableText.dropsubref(urn)
	if CitableText.isrange(trimmed)
		psg = CitableText.rangebegin(trimmed)
		CitableText.addpassage(urn,psg)
	else
		urn
	end
end

# ╔═╡ f7b6b1ce-eb2b-456f-8102-2d8fba838382
# Compose an HTML string for a row of tokens
function tokenizeRow(row, editorsrepo)
    textconfig = citation_df(editorsrepo)


	reduced = baseurn(row.passage)
	citation = "<b>" * passagecomponent(reduced)  * "</b> "
	ortho = orthographyforurn(textconfig, reduced)
	
	if ortho === nothing
		"<p class='warn'>⚠️  $(citation). No text configured</p>"
	else
	
		txt = normednode(reduced, editorsrepo)
		
		tokens = ortho.tokenizer(txt)
		highlighted = map(t -> formatToken(ortho, t.text), tokens)
		html = join(highlighted, " ")
		
		#"<p>$(citation) $(html)</p>"
		"<p><b>$(reduced.urn)</b> $(html)</p>"
	
	end
end

# ╔═╡ 4f4c5fd2-5219-4dc1-bdb2-9e48b3857966
begin
	if isempty(surface)
		md""
	else
		sdse = surfaceDse(Cite2Urn(surface), editorsrepo())
		htmlout = []
		try 
			for r in eachrow(sdse)
				push!(htmlout, tokenizeRow(r, editorsrepo()))
			end
		catch  e
			md"Error. $(e)"
		end
		HTML(join(htmlout,"\n"))
	end
end

# ╔═╡ Cell order:
# ╟─8cd70daf-566d-423d-931c-e5021ad2778a
# ╟─766e600d-200c-4421-9a21-a8fa0aa6a4a7
# ╟─17ebe116-0d7f-4051-a548-1573121a33c9
# ╟─35255eb9-1f54-4f9d-8c58-2d450e09dff9
# ╟─617ce64a-d7b1-4f66-8bd0-f7a240a929a7
# ╟─8d407e7a-1201-4dd3-bddd-368362037205
# ╟─ee2f04c1-42bb-46bb-a381-b12138e550ee
# ╟─834a67df-8c8b-47c6-aa3e-20297576019a
# ╟─8fcf792e-71eb-48d9-b0e6-e7e175628ccd
# ╟─9e6f8bf9-4aa7-4253-ba3f-695b13ca6def
# ╟─06bfa57d-2bbb-498e-b68e-2892d7186245
# ╟─ad541819-7d4f-4812-8476-8a307c5c1f87
# ╟─73839e47-8199-4755-8d55-362185907c45
# ╟─3dd88640-e31f-4400-9c34-2adc2cd4c532
# ╟─4f4c5fd2-5219-4dc1-bdb2-9e48b3857966
# ╟─ea1b6e21-7625-4f8f-a345-8e96449c0757
# ╟─fd401bd7-38e5-44b5-8131-dbe5eb4fe41b
# ╟─066b9181-9d41-4013-81b2-bcc37878ab68
# ╟─5cba9a9c-74cc-4363-a1ff-026b7b3999ea
# ╟─71d7a180-5742-415c-9013-d3d1c0ca920c
# ╟─59fbd3de-ea0e-4b96-800c-d5d8a7272922
# ╟─1814e3b1-8711-4afd-9987-a41d85fd56d9
# ╟─f7b6b1ce-eb2b-456f-8102-2d8fba838382
# ╟─3dd9b96b-8bca-4d5d-98dc-a54e00c75030
# ╟─987266ac-26b4-49b5-82ab-9719a63f6a3d
# ╟─32614e8a-6a69-48c3-ac02-2a6047ae711a
# ╟─8bf92039-8779-4fab-880b-f2ef58746103
# ╟─a771c143-01ca-45f8-a628-eaa66cb704a7
# ╟─ec0f3c61-cf3b-4e4c-8419-176626a0888c
# ╟─43734e4f-2efc-4f12-81ac-bce7bf7ada0a
# ╟─080b744e-8f14-406d-bdd2-fbcd3c1ec753
# ╟─806b3733-6c06-4956-8b86-aa096f060ac6
# ╟─a5ee0d67-60d3-42eb-b551-4463e7c50f2c
# ╟─476c9ae2-0dd7-4603-b529-17c229d83f7e
# ╟─9913000f-295a-41e3-bdfa-003774d3f574
