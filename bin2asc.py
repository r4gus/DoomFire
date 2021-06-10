filename = 'bf.wasm'
binary = None
with open(filename, 'rb') as f:
    content = f.read()
    binary = ", ".join("0x{:02x}".format(c) for c in content)
print(binary)
