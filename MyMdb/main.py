from flask import Flask, request, jsonify, flash, session, redirect, url_for, render_template
from flask_httpauth import HTTPBasicAuth
import re, json
from urllib.parse import unquote

from pymongo import MongoClient

client = MongoClient('localhost', 27017)
db = client['MDB']

session_counter = 0

app = Flask(__name__)
auth = HTTPBasicAuth()
app.secret_key = "secret"

User_DATA = db.user.find({}, {"_id": 0})[0]


@app.route('/add_data', methods=["GET", "POST"])
def add_data():
    if request.method == 'GET' and len(session) > 0:

        if session['username'] == User_DATA['username']:
            return render_template('add_data.html')

    if request.method == 'POST' and len(session) > 0:

        if session['username'] == User_DATA['username']:
            temp_var = request.get_data()
            temp_var = temp_var.decode('utf-8')
            temp_list = temp_var.split("&")

            popular = float(temp_list[0].split("=")[-1])

            director = str(temp_list[1].split("=")[-1])

            genre = ("".join(str(temp_list[2].split("=")[-1])).replace('"', '')).split("%2")

            imdb_score = float(str(temp_list[3].split("=")[-1]))

            name = str(str(temp_list[4].split("=")[-1]).replace('"', ''))

            data_on = {
                "99popularity": popular,
                "director": director,
                "genre": genre,
                "imdb_score": imdb_score,
                "name": name
            }
            try:
                cursor = db.movies.find({"name": name})
                results = list(cursor)
                if len(results) == 0:
                    db.movies.insert_one(data_on)
                    return render_template('Ok.html')
                else:
                    return "Movie data already Exists   " + "<br> <a href = '/add_data'>" + "click here to add data</a>"
            except Exception as e:
                return "Something went wrong! " + str(e)

        else:
            return "Not a admin user Not allowed"
    else:
        return render_template("login.html")


@app.route("/delete", methods=["POST", "GET"])
def movie_delete():
    if request.method == 'GET' and len(session) > 0:

        if session['username'] == User_DATA['username']:
            return render_template('del.html')

    if request.method == 'POST' and len(session) > 0:

        if session['username'] == User_DATA['username']:
            temp_var = request.get_data()
            temp_var = temp_var.decode('utf-8')
            temp_var = temp_var.split("=")[-1]
            cursor = db.movies.find({"name": temp_var})
            results = list(cursor)
            if len(results) != 0:
                myquery = {"name": temp_var}
                db.movies.delete_one(myquery)
            else:
                return "NO RECORD FOUND requested delete is not possible"

            return "Data about " + temp_var + " is deleted from database"
        return render_template("login.html")
    else:
        return render_template("login.html")


@app.route('/home')
def my_home():

    datavalue = {}
    datavalue["data"] = []
    cursor = db.movies.find({}, {"_id": 0})

    datavalue["data"] = [record for record in cursor]

    return jsonify(datavalue["data"])


@app.route('/landing')
def landing():
    return "<br><a href = '/home'>" + "click here for Homepage</a>&nbsp;&nbsp;&nbsp;" + \
           "<a href = '/add_data'>" + "click here to add data</a>&nbsp;&nbsp;&nbsp;" + \
           "<a href = '/delete'>" + "click here to delete data</a>&nbsp;&nbsp;&nbsp;" + \
           "<a href = '/search_by_name'>" + "click here to Search with movie name </a>&nbsp;&nbsp;&nbsp;" + \
           "<a href = '/search_by_genre'>" + "click here to Search with genre </a>&nbsp;&nbsp;&nbsp;"+\
            "<a href = '/edit'>" + "click here to Edit data  </a>&nbsp;&nbsp;&nbsp;"



@app.route('/search_by_name', methods=['GET', "POST"])
def search_by_name():
    if request.method == 'GET':
        return render_template("search.html")
    if request.method == 'POST':
        print(request.method)
        temp_var = request.get_data()
        temp_var = temp_var.decode('utf-8')
        temp_var = temp_var.split("=")[-1]
        movie_name = temp_var
        datavalue = {}
        datavalue["data"] = []
        cursor = db.movies.find({"name": movie_name}, {"_id": 0})

        datavalue["data"] = [record for record in cursor]
        if datavalue["data"] != []:
            return jsonify(datavalue)
        else:
            return "Record Not Found"

@app.route('/edit1', methods=[ "POST"])
def edit1():

    if request.method == 'POST':
        if len(session) > 0 and session['username'] == User_DATA['username']:
            temp_var = request.get_data()
            temp_var = temp_var.decode('utf-8')
            temp_list = temp_var.split("&")

            popular = float(unquote(temp_list[0].split("=")[-1]))

            director = str(unquote(temp_list[1].split("=")[-1])).replace("+"," ")

            genre = ("".join(str(unquote(temp_list[2])).split("=")[-1]).strip()).replace('"', '').replace("'",'').replace("+"," ").replace("[","").replace("]","").split(",")

            imdb_score = float(str(unquote(temp_list[3]).split("=")[-1]))

            name = str(str(unquote(temp_list[4]).split("=")[-1]).replace('"', '')).replace("'",'').replace("+"," ")

            data_on = {
                "99popularity": popular,
                "director": director,
                "genre": genre,
                "imdb_score": imdb_score,
                "name": name
            }
            newvalues = {"$set": data_on}
            db.movies.update_one({"name":name}, newvalues)
            flash("Update success ","success")
            return redirect(url_for("edit"))
        else:
            return redirect(url_for('login'))




@app.route('/edit', methods=['GET', "POST"])
def edit():
    # search_by_genre/?option="War"
    if request.method == 'GET':
        if len(session) > 0 and session['username'] == User_DATA['username']:

            return render_template("edit1.html")
        else: return redirect(url_for('login'))
    if request.method == 'POST':
        if len(session) > 0 and session['username'] == User_DATA['username']:
            temp_var = request.get_data()
            temp_var = temp_var.decode('utf-8')
            temp_var = temp_var.split("=")[-1]
            movie_name = temp_var

            datavalue = {}
            datavalue["data"] = []
            cursor = db.movies.find({"name": movie_name}, {"_id": 0})

            datavalue["data"] = [record for record in cursor]

            if datavalue["data"] != []:
                print(datavalue)
                datavalue = datavalue['data'][0]
                print(datavalue)
                return render_template("edit.html",popu=datavalue["99popularity"],dir=datavalue['director'],gen=datavalue['genre'],score=datavalue["imdb_score"],name=datavalue['name'])
            else:
                return "Record Not Found"
        else:
            return redirect(url_for('login'))



# @app.route('/index')
# def index():
#    if 'username' in session:
#
#       username = session['username']
#       return 'Logged in as ' + username + '<br>' + "<b><a href = '/logout'>click here to log out</a></b>"
#    return "You are not logged in <br><a href = '/login'>" + "click here to log in</a>"


@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'GET' and len(session) > 0:

        if session['username'] == User_DATA['username']:
            return redirect(url_for('my_home'))
    if request.method == 'POST':

        if request.form['username'] == User_DATA['username'] and request.form['password'] == User_DATA['password']:
            if len(session) > 0 and session['username'] == request.form['username']:
                flash("Already logged In ")

            session['username'] = request.form['username']
            session['password'] = request.form['password']

            return redirect(url_for('landing'))
    return render_template("login.html")


@app.route('/logout')
def logout():
    # remove the username from the session if it is there
    session.pop("username", None)
    session.pop("password", None)

    return redirect(url_for('login'))


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)
