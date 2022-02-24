

import random
from flask import Flask, request

app = Flask(__name__)

#main loop


#game outcomes

outcomes = {

    "rock":{
        "rock":"draw",
        "paper":"loss",
        "scissors":"win"
    },
    "paper":{
        "rock":"win",
        "paper":"draw",
        "scissors":"loss"
    },
    "scissors":{
        "rock":"loss",
        "paper":"win",
        "scissors":"draw"
    }
}

def conerted_outcome(numer):
    if numer ==1:
        return 'rock'
    elif numer == 2 :
        return  "paper"
    elif numer == 3:
        return "scissors"

@app.route("/",methods = ['GET'])
def game():

    while 1 :
        random_number = random.randint(1,3)
        computer_choice = conerted_outcome(random_number)
        user_choice = request.args["c"]
        try:
            res ={

                "User_choice:":user_choice,
                "Computer_choice:":computer_choice,
                "Result":str(outcomes[user_choice][computer_choice])
            }
            print(res,type(res))


            return res
        except Exception as e:
            print("Invalid Input !!")
            break



if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0',port=5000)