

# Get first <num> pages in <category>
response = client.query(list: 'categorymembers', cmtitle: '<category>', cmlimit: <num>)
# Get the names of the pages
response.data["categorymembers"].map{ |p| p["title"]}


response = client.query(list: 'categorymembers', cmtitle: 'Category:Pages using deprecated coordinates format', cmlimit: 1000)
