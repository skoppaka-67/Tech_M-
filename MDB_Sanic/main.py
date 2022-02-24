from sanic import Sanic,response,request
from sanic.response import json


app = Sanic("imdb")



@app.route("/")
async def index(request):
    print(request.cookies.get)

    return await response.file('./templates/index.html')



@app.route('/login', methods=['GET', 'POST'])
async def login(request):

    if request.method == 'GET':
        return await response.file('./templates/login.html')
    elif request.method == 'POST':
        print(request.form)
        if request.form['username'] == "admin" and request.form['password'] == "fynd1":
            print(request.cookies)
    #         if len(session) > 0 and session['username'] == request.form['username']:
    #             flash("Already logged In ")
    #
    #         session['username'] = request.form['username']
    #         session['password'] = request.form['password']
    #         token = jwt.encode({'username':'admin','exp':datetime.datetime.utcnow()+datetime.timedelta(minutes=5)},app.config['SECRET_KEY'])
    #         session['token'] = token.decode('UTF-8')
    #         print("sessiontoken",session["token"])
    #
    #         return redirect(url_for('index'))
    # return render_template("login.html")












if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8000,debug=True)