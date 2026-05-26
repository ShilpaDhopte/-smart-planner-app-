import QtQuick 2.4
import Lomiri.Components 1.3
import QtQuick.LocalStorage 2.0

MainView {
    width: units.gu(45)
    height: units.gu(75)

    // THEME
    property bool darkMode: true
    property color bgColor: darkMode ? "#121212" : "#F5F7FA"
    property color cardColor: darkMode ? "#1E1E1E" : "#FFFFFF"
    property color textColor: darkMode ? "#FFFFFF" : "#000000"
    property color accent: "#00C853"

    // DATABASE
    function getDB() {
        return LocalStorage.openDatabaseSync(
            "SmartPlannerDB",
            "1.0",
            "Planner Database",
            1000000
        )
    }

    function initDB() {

        var db = getDB()

        db.transaction(function(tx) {

            tx.executeSql(
                "CREATE TABLE IF NOT EXISTS tasks (id INTEGER PRIMARY KEY, name TEXT, desc TEXT, time TEXT, date TEXT)"
            )

            tx.executeSql(
                "CREATE TABLE IF NOT EXISTS habits (id INTEGER PRIMARY KEY, name TEXT, streak INTEGER)"
            )

            tx.executeSql(
                "CREATE TABLE IF NOT EXISTS expenses (id INTEGER PRIMARY KEY, name TEXT, amount REAL, category TEXT, note TEXT)"
            )
        })
    }

    PageStack {
        id: stack

        Component.onCompleted: {
            initDB()
            push(home)
        }

        // HOME PAGE
        Component {
            id: home

            Page {

                header: PageHeader {
                    title: "Smart Planner"
                }

                Rectangle {

                    anchors.fill: parent
                    color: bgColor

                    Column {

                        anchors.centerIn: parent
                        spacing: units.gu(3)
                        width: parent.width * 0.85

                        Label {
                            text: "SMART PLANNER"
                            font.pixelSize: 34
                            color: textColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Button {

                            text: darkMode ? "Light Mode" : "Dark Mode"
                            width: parent.width

                            onClicked: {
                                darkMode = !darkMode
                            }
                        }

                        Button {

                            text: "Daily Planner"
                            width: parent.width
                            color: accent

                            onClicked: {
                                stack.push(planner)
                            }
                        }

                        Button {

                            text: "Habit Tracker"
                            width: parent.width
                            color: "#2196F3"

                            onClicked: {
                                stack.push(habit)
                            }
                        }

                        Button {

                            text: "Expense Tracker"
                            width: parent.width
                            color: "#FF9800"

                            onClicked: {
                                stack.push(expense)
                            }
                        }
                    }
                }
            }
        }

        // DAILY PLANNER
      
Component {
    id: planner

    Page {

        header: PageHeader {
            title: "Daily Planner"
        }

        ListModel {
            id: tasks
        }

        Component.onCompleted: {

            tasks.clear()

            var db = getDB()

            db.transaction(function(tx) {

                var rs = tx.executeSql("SELECT * FROM tasks")

                for (var i = 0; i < rs.rows.length; i++) {

                    var row = rs.rows.item(i)

                    tasks.append({
                        name: row.name,
                        desc: row.desc,
                        time: row.time,
                        date: row.date,
                        done: false
                    })
                }
            })
        }

        Rectangle {

            anchors.fill: parent
            color: bgColor

            Flickable {

                anchors.fill: parent

                contentWidth: parent.width
                contentHeight: plannerColumn.height + units.gu(5)

                Column {

                    id: plannerColumn

                    width: parent.width - units.gu(4)

                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)

                    spacing: units.gu(2)

                    // TASK TITLE
                    TextField {
                        id: title
                        placeholderText: "Task Title"
                        width: parent.width
                    }

                    // DESCRIPTION
                    TextField {
                        id: desc
                        placeholderText: "Description"
                        width: parent.width
                    }

                    // TIME
                    TextField {
                        id: time
                        placeholderText: "Time"
                        width: parent.width
                    }

                    // DATE
                    TextField {
                        id: date
                        placeholderText: "Date"
                        width: parent.width
                    }

                    // ADD BUTTON
                    Button {

                        text: "Add Task"
                        width: parent.width
                        color: accent

                        onClicked: {

                            console.log("BUTTON CLICKED")

                            tasks.append({

                                name: title.text,
                                desc: desc.text,
                                time: time.text,
                                date: date.text,
                                done: false
                            })

                            console.log("TASK COUNT:", tasks.count)

                            // SAVE TO DATABASE
                            var db = getDB()

                            db.transaction(function(tx) {

                                tx.executeSql(
                                    "INSERT INTO tasks (name, desc, time, date) VALUES (?, ?, ?, ?)",
                                    [title.text, desc.text, time.text, date.text]
                                )
                            })

                            // CLEAR INPUTS
                            title.text = ""
                            desc.text = ""
                            time.text = ""
                            date.text = ""
                        }
                    }

                    // TASK COUNT
                    Text {

                        text: "Tasks: " + tasks.count

                        color: accent
                        font.pixelSize: 22
                    }

                    // TASKS DISPLAY
                    Column {

                        width: parent.width
                        spacing: units.gu(2)

                        Repeater {

                            model: tasks

                            delegate: Rectangle {

                                width: parent.width
                                height: units.gu(22)

                                radius: 10

                                color: done ?
                                       "#2E7D32" :
                                       cardColor

                                border.color: accent
                                border.width: 1

                                Column {

                                    anchors.fill: parent
                                    anchors.margins: units.gu(1)

                                    spacing: units.gu(1)

                                    Text {

                                        text: "📌 " + name

                                        color: textColor
                                        font.pixelSize: 20
                                    }

                                    Text {

                                        text: "📝 " + desc

                                        color: textColor
                                    }

                                    Text {

                                        text: "⏰ " + time

                                        color: textColor
                                    }

                                    Text {

                                        text: "📅 " + date

                                        color: textColor
                                    }

                                    Row {

                                        spacing: units.gu(2)

                                        CheckBox {

                                            checked: done

                                            onCheckedChanged: {

                                                tasks.setProperty(
                                                    index,
                                                    "done",
                                                    checked
                                                )
                                            }
                                        }

                                        Button {

                                            text: "Delete"

                                            onClicked: {
                                                tasks.remove(index)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
        // HABIT TRACKER
Component {
    id: habit

    Page {

        header: PageHeader {
            title: "Habit Tracker"
        }

        ListModel {
            id: habits
        }

        property int doneCount: 0

        property int dailyGoal: 5

        Rectangle {

            anchors.fill: parent

            color: bgColor

            Column {

                anchors.fill: parent

                // FIXED SPACING
                anchors.topMargin: units.gu(10)

                anchors.leftMargin: units.gu(2)

                anchors.rightMargin: units.gu(2)

                anchors.bottomMargin: units.gu(2)

                spacing: units.gu(2)

                // INPUT FIELD
                TextField {

                    id: habitInput

                    width: parent.width

                    height: units.gu(6)

                    placeholderText: "Enter Habit Name"
                }

                // ADD BUTTON
                Button {

                    text: "Add Habit"

                    width: parent.width

                    color: "#2196F3"

                    onClicked: {

                        if (
                            habitInput.text !== ""
                        ) {

                            habits.append({

                                name: habitInput.text,

                                streak: 0,

                                done: false
                            })

                            habitInput.text = ""
                        }
                    }
                }

                // COMPLETED TEXT
                Text {

                    text:
                        "Completed: " +
                        doneCount +
                        " / " +
                        dailyGoal

                    color: "#2196F3"

                    font.pixelSize: 22
                }

                // PROGRESS BAR
                Rectangle {

                    width: parent.width

                    height: units.gu(2)

                    radius: 5

                    color: "#444"

                    Rectangle {

                        width:
                            dailyGoal === 0 ?
                            0 :
                            (doneCount / dailyGoal)
                            * parent.width

                        height: parent.height

                        radius: 5

                        color: "#2196F3"
                    }
                }

                // MOTIVATION TEXT
                Text {

                    text:
                        doneCount >= dailyGoal ?
                        "Goal Completed!" :
                        "Keep Going!"

                    color: "#2196F3"

                    font.pixelSize: 20
                }

                // TOTAL HABITS
                Text {

                    text:
                        "Habits: " +
                        habits.count

                    color: "#2196F3"

                    font.pixelSize: 22
                }

                // HABIT LIST
                ListView {

                    width: parent.width

                    height: units.gu(35)

                    model: habits

                    clip: true

                    delegate: Rectangle {

                        width: parent.width

                        height: units.gu(18)

                        radius: 10

                        color:
                            done ?
                            "#1565C0" :
                            cardColor

                        border.color: "#2196F3"

                        border.width: 1

                        Column {

                            anchors.fill: parent

                            anchors.margins:
                                units.gu(1)

                            spacing:
                                units.gu(1)

                            // HABIT NAME
                            Text {

                                text: name

                                color: "#FFFFFF"

                                font.pixelSize: 20
                            }

                            // STREAK
                            Text {

                                text:
                                    "Streak: " +
                                    streak

                                color: "#FFFFFF"
                            }

                            Row {

                                spacing:
                                    units.gu(2)

                                // CHECKBOX
                                CheckBox {

                                    checked: done

                                    onCheckedChanged: {

                                        habits.setProperty(
                                            index,
                                            "done",
                                            checked
                                        )

                                        if (checked) {

                                            doneCount++

                                            habits.setProperty(
                                                index,
                                                "streak",
                                                streak + 1
                                            )

                                        } else {

                                            doneCount--
                                        }
                                    }
                                }

                                // DELETE BUTTON
                                Button {

                                    text: "Delete"

                                    onClicked: {

                                        if (done) {
                                            doneCount--
                                        }

                                        habits.remove(index)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
       // EXPENSE TRACKER
Component {
    id: expense

    Page {

        header: PageHeader {
            title: "Expense Tracker"
        }

        ListModel {
            id: expenses
        }

        property double total: 0

        Rectangle {

            anchors.fill: parent

            color: bgColor

            Column {

                anchors.fill: parent

                anchors.topMargin: units.gu(10)

                anchors.leftMargin: units.gu(2)

                anchors.rightMargin: units.gu(2)

                anchors.bottomMargin: units.gu(2)

                spacing: units.gu(2)

                // EXPENSE NAME
                TextField {

                    id: expenseName

                    width: parent.width

                    height: units.gu(6)

                    placeholderText: "Expense Name"
                }

                // AMOUNT
                TextField {

                    id: amount

                    width: parent.width

                    height: units.gu(6)

                    placeholderText: "Amount"
                }

                // CATEGORY
                TextField {

                    id: category

                    width: parent.width

                    height: units.gu(6)

                    placeholderText: "Category"
                }

                // NOTE
                TextField {

                    id: note

                    width: parent.width

                    height: units.gu(6)

                    placeholderText: "Note"
                }

                // ADD BUTTON
                Button {

                    text: "Add Expense"

                    width: parent.width

                    color: "#FF9800"

                    onClicked: {

                        if (
                            expenseName.text !== ""
                            &&
                            amount.text !== ""
                        ) {

                            var amt =
                                parseFloat(amount.text)

                            expenses.append({

                                name:
                                    expenseName.text,

                                amount: amt,

                                category:
                                    category.text,

                                note:
                                    note.text
                            })

                            // UPDATE TOTAL
                            total += amt

                            // CLEAR INPUTS
                            expenseName.text = ""

                            amount.text = ""

                            category.text = ""

                            note.text = ""
                        }
                    }
                }

                // TOTAL DISPLAY
                Text {

                    text:
                        "Total: ₹ " + total

                    color: "#FFFFFF"

                    font.pixelSize: 24
                }

                // TOTAL COUNT
                Text {

                    text:
                        "Expenses: "
                        + expenses.count

                    color: "#FF9800"

                    font.pixelSize: 20
                }

                // EXPENSE LIST
                ListView {

                    width: parent.width

                    height: units.gu(35)

                    model: expenses

                    clip: true

                    delegate: Rectangle {

                        width: parent.width

                        height: units.gu(22)

                        radius: 10

                        color: cardColor

                        border.color:
                            "#FF9800"

                        border.width: 1

                        Column {

                            anchors.fill:
                                parent

                            anchors.margins:
                                units.gu(1)

                            spacing:
                                units.gu(1)

                            // NAME
                            Text {

                                text: name

                                color:
                                    "#FFFFFF"

                                font.pixelSize:
                                    20
                            }

                            // AMOUNT
                            Text {

                                text:
                                    "₹ "
                                    + amount

                                color:
                                    "#FF9800"

                                font.pixelSize:
                                    18
                            }

                            // CATEGORY
                            Text {

                                text:
                                    "Category: "
                                    + category

                                color:
                                    "#FFFFFF"
                            }

                            // NOTE
                            Text {

                                text:
                                    "Note: "
                                    + note

                                color:
                                    "#FFFFFF"
                            }

                            // DELETE BUTTON
                            Button {

                                text: "Delete"

                                onClicked: {

                                    total -= amount

                                    expenses.remove(
                                        index
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// CLOSE PageStack
}

// CLOSE MainView
}
