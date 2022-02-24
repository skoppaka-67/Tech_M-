import copy
li = [ "cat","dog","act","tar","tac","rat","cat"]

def ann_group(li):
    out_list = []
    map = {}
    for word in li:
        s_word = "".join(sorted(word))
        if s_word not in map:
            for sub_word in li:
                s_sub_word = "".join(sorted(sub_word))
                if s_word == s_sub_word:
                        out_list.append(sub_word)

            map[s_word] = copy.deepcopy(out_list)
            out_list.clear()
        else:
            continue

    return map


print(ann_group(li).values())

