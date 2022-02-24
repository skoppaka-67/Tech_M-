from flask import  Flask, request
import random

app =  Flask(__name__)


res_dict = {

    "rock":{
        "rock":"draw",
        "paper":"loss",
        "scissor":"win"
    },

    "paper": {
        "rock": "win",
        "paper": "draw",
        "scissor": "loss"
    },

    "scissor":{
        "rock":"loss",
        "paper":"win",
        "scissor":"draw"
    }


}


def value_conv(n):

    if n == 1:
        return "rock"
    elif n == 2:
        return "paper"
    elif n == 3:
        return "scissor"


@app.route("/",methods=['GET'])
def game():
    while True:

        user_input = request.args["ch"]
        computer_input =  value_conv(random.randint(1,3))
        print(user_input,computer_input)
        try:
            # return {"1.Your Choice": user_input, "2.Computer Choice": computer_input,
            #     "3.Result": res_dict[user_input][computer_input] }
            return "Result - " + str(res_dict[user_input][computer_input])



        except Exception as e:
            return "Invalid Input"


if __name__ == '__main__':
    app.run(host="0.0.0.0",port=5000)