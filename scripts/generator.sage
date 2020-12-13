# Generator helpers
def mi_vars(*latex_names, random_order=True):
    """
    Given one or more `latex_names` of strings, returns a tuple
    of Sage variables. `random_order` names them so that they appear
    in expressions in a random order.
    """
    stamp = randrange(100000,999999)
    indices = list(range(len(latex_names)))
    if random_order:
        shuffle(indices)
    import string
    random_letter = choice(list(string.ascii_lowercase))
    return (var(f"{random_letter}_mi_var_{stamp}_{indices[i]}", latex_name=name) for i, name in enumerate(latex_names))

def shuffled_equation(*terms):
    """
    Represents the equation sum(terms)==0, but with terms shuffled randomly
    to each side.
    """
    new_equation = (SR(0)==0)
    for term in terms:
        if choice([True,False]):
            new_equation += (SR(term)==0)
        else:
            new_equation += (0==-SR(term))
    return new_equation*choice([-1,1])

def base64_graphic(obj, file_format="svg"):
    """
    Generates Base64 encoding of the graphic in the requested file_format.
    """
    if not isinstance(obj,Graphics):
        raise TypeError("Only graphics may be encoded as base64")
    if file_format not in ["svg", "png"]:
        raise ValueError("Invalid file format")
    filename = tmp_filename(ext=f'.{file_format}')
    obj.save(filename)
    with open(filename, 'rb') as f:
        from base64 import b64encode
        b64 = b64encode(f.read())
    return b64

def data_url_graphic(obj, file_format="svg"):
    """
    Generates Data URL representing the graphic in the requested file_format.
    """
    b64 = base64_graphic(obj, file_format=file_format).decode('utf-8')
    if file_format=="svg":
        file_format = "svg+xml"
    return f"data:image/{file_format};base64,{b64}"

def latex_system_from_matrix(matrix, variables="x", alpha_mode=False, variable_list=[]):
    # Augment with zero vector if not already augmented
    if not matrix.subdivisions()[1]:
        matrix=matrix.augment(zero_vector(ZZ, len(matrix.rows())), subdivide=true)
    num_vars = matrix.subdivisions()[1][0]
    # Start using requested variables
    system_vars = variable_list
    # Conveniently add xyzwv if requested
    if alpha_mode:
        system_vars += list(var("x y z w v"))
    # Finally fall back to x_n as needed
    system_vars += [var(f"{variables}_{n+1}") for n in range(num_vars)]
    # Build matrix
    latex_output = "\\begin{matrix}\n"
    for row in matrix.rows():
        if row[0]!= 0:
            latex_output += latex(row[0]*system_vars[0])
            previous_terms = True
        else:
            previous_terms = False
        for n,cell in enumerate(row[1:num_vars]):
            latex_output += " & "
            if cell < 0 and previous_terms:
                latex_output += " - "
            elif cell > 0 and previous_terms:
                latex_output += " + "
            latex_output += " & "
            if cell != 0:
                latex_output += latex(cell.abs()*system_vars[n+1])
            if not previous_terms:
                previous_terms = bool(cell!=0)
        if not previous_terms:
            latex_output += " 0 "
        latex_output += " & = & "
        latex_output += latex(row[num_vars])
        latex_output += "\\\\\n"
    latex_output += "\\end{matrix}"
    return latex_output

def latexify(obj):
    if isinstance(obj,str):
        return obj
    elif isinstance(obj,list):
        return [latexify(item) for item in obj]
    elif isinstance(obj,dict):
        return {key:latexify(obj[key]) for key in obj.keys()}
    else:
        return str(latex(obj))

import sys,json
if sys.argv[3]:
    generator_path = sys.argv[1]
    amount = int(sys.argv[2])
    public = (sys.argv[3]=="PUBLIC")
    load(generator_path) # provides generator() function
    seeds = []
    for i in range(amount):
        if public:
            seed = i % 1000
        else:
            set_random_seed()
            seed = randrange(1000,10000)
        set_random_seed(seed)
        seeds.append({"seed":int(seed),"values":latexify(generator())})
    print(json.dumps(seeds))
