### A Pluto.jl notebook ###
# v0.14.4

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

# ╔═╡ d859973a-78f0-11eb-05a4-13dba1f0cb9e
# build environment
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
	using Lycian
	using Markdown
	using Orthography
	using PolytonicGreek
	Pkg.status()
end

# ╔═╡ 5495ea1c-7b56-11eb-39ed-d1078b0808b0
md"> ## Validation: cataloging texts"

# ╔═╡ c8c4f0a0-7b50-11eb-0be9-27b71bddbc9f
html"""
<style>
.splash {
	background-color: #f0f7fb;
}
</style>
"""

# ╔═╡ 1e9d6620-78f3-11eb-3f66-7748e8758e08
@bind loadem Button("Load/reload data")

# ╔═╡ 493a315c-78f2-11eb-08e1-137d9a802802
begin
	loadem
	nbversion = Pkg.TOML.parse(read("Project.toml", String))["version"]
	md"""
	## Validating notebook
	
	- How to edit: see the [MID handbook](https://hcmid.github.io/tutorial2021/)
	- Version: this is version **$(nbversion)** of the MID validation notebook.
	
	
	
	"""
end

# ╔═╡ 4aacb152-79b2-11eb-349a-cfe86f526399
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


# ╔═╡ 8331f0b2-7900-11eb-2496-117104c3cfc1
md"""

> ## Verification: DSE indexing

"""

# ╔═╡ 8b46877e-78f7-11eb-2bcd-dbe2ca896eb0
md"""

### Verify *completeness* of indexing


*Check completeness of indexing by following linked thumb to overlay view in the Image Citation Tool*
"""

# ╔═╡ 9b3a7606-78f7-11eb-1248-3f48982089c3
md"*Height of thumbnail image*: $(@bind thumbht Slider(150:500, show_value=true))"


# ╔═╡ 7c715a3c-78f7-11eb-2be0-a71beeed0f3e
md"""
### Verify *accuracy* of indexing

*Check that diplomatic text and indexed image correspond.*


"""

# ╔═╡ b4ab331a-78f6-11eb-33f9-c3fde8bed5d1
md"""
*Maximum width of image*: $(@bind w Slider(200:1200, show_value=true))

"""


# ╔═╡ 70f42154-7900-11eb-325d-9b20517cb744
md"""

> ## Verification:  orthography

"""

# ╔═╡ 6f96dc0c-78f6-11eb-2894-f7c474078043
md"""

---

---


> ### Functions

You don't need to look at the rest of the notebook unless you're curious about how it works.  The following cells define the functions that retreive data from your editing repository, validate it, and format it for visual verification.


"""

# ╔═╡ 509c782a-79b4-11eb-0801-a1d0c9b4ffb3
md"> Formatting visualizations for verification"

# ╔═╡ 283df9ae-7904-11eb-1b77-b74be19a859c
# Wrap tokens with invalid orthography in HTML tag
function formatToken(ortho, s)
	
	if validstring(ortho, s)
			s
	else
		"""<span class='invalid'>$(s)</span>"""
	end
end

# ╔═╡ 62550016-7b59-11eb-1f01-3de7603752cc
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

# ╔═╡ ac2d4f3c-7925-11eb-3f8c-957b9de49d88
css = html"""
<style>
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

# ╔═╡ c5d65e86-79b3-11eb-2c3f-d5e5c8efcc5a
md"> Repository and image services to use"

# ╔═╡ 54a24382-78f1-11eb-24c8-198fc54ef67e
# Create EditingRepository for this notebook's repository
# Since the notebook is in the `notebooks` subdirectory of the repository,
# we can just use the parent directory (dirname() in julia) for the
# root directory.
function editorsrepo() 
    EditingRepository( dirname(pwd()), "editions", "dse", "config")
end

# ╔═╡ 6a94c362-7b59-11eb-2a6f-77375afae47e
begin
	loadem
	editorsrepo() |> catalogcheck
end

# ╔═╡ cc19dac4-78f6-11eb-2269-453e2b1664fd
# Base URL for an ImageCitationTool
function ict()
	"http://www.homermultitext.org/ict2/?"
end

# ╔═╡ d1969604-78f6-11eb-3231-1570919758aa
# API to work with an IIIF image service
function iiifsvc()
	IIIFservice("http://www.homermultitext.org/iipsrv",
	"/project/homer/pyramidal/deepzoom")
end

# ╔═╡ 6db097fc-78f1-11eb-0713-59bf9132af2e
md"> Texts in the repository"

# ╔═╡ 7f130fb6-78f1-11eb-3143-a7208d3a9559
# Build a dataframe for catalog of all online texts
function catalogedtexts(repo::EditingRepository)
	allcataloged = fromfile(CatalogedText, repo.root * "/" * repo.configs * "/catalog.cex")
	filter(row -> row.online, allcataloged)
end

# ╔═╡ e45a445c-78f1-11eb-3ef5-81b1b7adec63
# Find CTS URNs of all texts cataloged as online
function texturns(repo)
    texts = catalogedtexts(repo)
    texts[:, :urn]
end

# ╔═╡ 1829efee-78f2-11eb-06bd-ddad8fb26622
# Use configuratoin infor to compose diplomatic text for all 
# all texts in the repository.
function diplpassages(editorsrepo)
    urnlist = texturns(editorsrepo)
	try 
		diplomaticarrays = map(u -> diplomaticnodes(editorsrepo, u), urnlist)
		singlearray = reduce(vcat, diplomaticarrays)
		filter(psg -> psg !== nothing, singlearray)
	catch e
		msg = "<div class='danger'><h1>🧨🧨 Markup error 🧨🧨</h1><p><b>$(e)</b></p></div>"
		HTML(msg)
	end
end

# ╔═╡ 85119632-7903-11eb-3291-078d8c56087c
# Use configuratoin infor to compose normalized text for all 
# all texts in the repository.
function normedpassages(editorsrepo)
    urnlist = texturns(editorsrepo)
	try 
		normedarrays = map(u -> normalizednodes(editorsrepo, u), urnlist)
		singlearray = reduce(vcat, normedarrays)
		filter(psg -> psg !== nothing, singlearray)
	catch e
		msg = "<div class='danger'><h1>🧨🧨 Markup error 🧨🧨</h1><p><b>$(e)</b></p></div>"
		HTML(msg)
	end
end

# ╔═╡ b30ccd06-78f2-11eb-2b03-8bff7ab09aa6
# True if last component of CTS URN passage is "ref".
# We use this to exclude elements with this identifier, 
# like HMT scholia
function isref(urn::CtsUrn)::Bool
    # True if last part of 
    passageparts(urn)[end] == "ref"
end

# ╔═╡ 5c472d86-78f2-11eb-2ead-5196f07a5869
# Collect diplomatic text for a text passage identified by URN.
# The URN should either match a citable node, or be a containing node
# for one or more citable nodes.  Ranges URNs are not supported.
function diplnode(urn, repo)
	diplomaticpassages = repo |> diplpassages
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

# ╔═╡ 06d139d4-78f5-11eb-0247-df4126777208
# Compose markdown for one row of display interleaving citable
# text passage and indexed image.
function mdForDseRow(row::DataFrameRow)
	citation = "**" * passagecomponent(row.passage)  * "** "

	
	txt = diplnode(row.passage, editorsrepo())
	caption = passagecomponent(row.passage)
	
	img = linkedMarkdownImage(ict(), row.image, iiifsvc(), w, caption)
	
	#urn
	record = """$(citation) $(txt)

$(img)

---
"""
	record
end

# ╔═╡ 81656522-7903-11eb-2ed7-53a05f05ebd6
# Collect diplomatic text for a text passage identified by URN.
# The URN should either match a citable node, or be a containing node
# for one or more citable nodes.  Ranges URNs are not supported.
function normednode(urn, repo)
	normalizedpassages = repo |> normedpassages
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

# ╔═╡ 6565f4b6-79b4-11eb-22ae-491ea4d70f46
md"> DSE indexing"

# ╔═╡ 58cdfb8e-78f3-11eb-2adb-7518ff306e2a
# Find all surfaces in reposistory
function uniquesurfaces(editorsrepo)
	
	try
		EditorsRepo.surfaces(editorsrepo)
	catch e
		msg = """<div class='danger'><h2>🧨🧨 Configuration error 🧨🧨</h2>
		<p><b>$(e)</b></p></div>
		"""
		HTML(msg)
	end
end

# ╔═╡ 37e5ea20-78f4-11eb-1dff-c36418158c7c
# Find DSE records for surface currently selected in popup menu.
function surfaceDse(surfurn, repo)
    alldse = dse_df(editorsrepo())
	filter(row -> row.surface == surfurn, alldse)
end

# ╔═╡ 0150956a-78f8-11eb-3ebd-793eefb046cb

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

# ╔═╡ a1c93e66-78f3-11eb-2ffc-3f5becceedc8
#Create list of text labels for popupmenu
function surfacemenu(editorsrepo)
	loadem
	surfurns = EditorsRepo.surfaces(editorsrepo)
	surflist = map(u -> u.urn, surfurns)
	# Add a blank entry so popup menu can come up without a selection
	pushfirst!( surflist, "")
end

# ╔═╡ c91e8142-78f3-11eb-3410-0d65bfb93f0a
md"""###  Choose a surface to verify

$(@bind surface Select(surfacemenu(editorsrepo())))
"""

# ╔═╡ 055b4a92-78f8-11eb-3b27-478beed207d2
# Display link for completeness view
begin
	if isempty(surface)
		md""
	else
		Markdown.parse(completenessView(Cite2Urn(surface), editorsrepo()))
	end
end

# ╔═╡ b4a23c4c-78f4-11eb-20d3-71eac58097c2
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

# ╔═╡ 36599fea-7902-11eb-2524-3bd9026f017c
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

# ╔═╡ 442b37f6-791a-11eb-16b7-536a71aee034
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

# ╔═╡ 7a11f584-7905-11eb-0ea6-1b8543a4e471
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
# ╟─d859973a-78f0-11eb-05a4-13dba1f0cb9e
# ╟─493a315c-78f2-11eb-08e1-137d9a802802
# ╟─4aacb152-79b2-11eb-349a-cfe86f526399
# ╟─5495ea1c-7b56-11eb-39ed-d1078b0808b0
# ╟─6a94c362-7b59-11eb-2a6f-77375afae47e
# ╟─c8c4f0a0-7b50-11eb-0be9-27b71bddbc9f
# ╟─1e9d6620-78f3-11eb-3f66-7748e8758e08
# ╟─c91e8142-78f3-11eb-3410-0d65bfb93f0a
# ╟─8331f0b2-7900-11eb-2496-117104c3cfc1
# ╟─8b46877e-78f7-11eb-2bcd-dbe2ca896eb0
# ╟─9b3a7606-78f7-11eb-1248-3f48982089c3
# ╟─055b4a92-78f8-11eb-3b27-478beed207d2
# ╟─7c715a3c-78f7-11eb-2be0-a71beeed0f3e
# ╟─b4ab331a-78f6-11eb-33f9-c3fde8bed5d1
# ╟─b4a23c4c-78f4-11eb-20d3-71eac58097c2
# ╟─70f42154-7900-11eb-325d-9b20517cb744
# ╟─7a11f584-7905-11eb-0ea6-1b8543a4e471
# ╟─6f96dc0c-78f6-11eb-2894-f7c474078043
# ╟─509c782a-79b4-11eb-0801-a1d0c9b4ffb3
# ╟─283df9ae-7904-11eb-1b77-b74be19a859c
# ╟─442b37f6-791a-11eb-16b7-536a71aee034
# ╟─06d139d4-78f5-11eb-0247-df4126777208
# ╟─0150956a-78f8-11eb-3ebd-793eefb046cb
# ╟─62550016-7b59-11eb-1f01-3de7603752cc
# ╟─ac2d4f3c-7925-11eb-3f8c-957b9de49d88
# ╟─c5d65e86-79b3-11eb-2c3f-d5e5c8efcc5a
# ╟─54a24382-78f1-11eb-24c8-198fc54ef67e
# ╟─cc19dac4-78f6-11eb-2269-453e2b1664fd
# ╟─d1969604-78f6-11eb-3231-1570919758aa
# ╟─6db097fc-78f1-11eb-0713-59bf9132af2e
# ╟─7f130fb6-78f1-11eb-3143-a7208d3a9559
# ╟─e45a445c-78f1-11eb-3ef5-81b1b7adec63
# ╠═1829efee-78f2-11eb-06bd-ddad8fb26622
# ╟─85119632-7903-11eb-3291-078d8c56087c
# ╟─5c472d86-78f2-11eb-2ead-5196f07a5869
# ╟─81656522-7903-11eb-2ed7-53a05f05ebd6
# ╟─b30ccd06-78f2-11eb-2b03-8bff7ab09aa6
# ╟─6565f4b6-79b4-11eb-22ae-491ea4d70f46
# ╟─58cdfb8e-78f3-11eb-2adb-7518ff306e2a
# ╟─37e5ea20-78f4-11eb-1dff-c36418158c7c
# ╟─a1c93e66-78f3-11eb-2ffc-3f5becceedc8
# ╟─36599fea-7902-11eb-2524-3bd9026f017c
