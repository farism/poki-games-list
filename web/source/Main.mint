record Game {
  name : String,
  author : String,
  upvote : String,
  downvote : String,
  defold : Bool,
  tags : Array(String),
  upvotenum : Maybe(Number),
  downvotenum : Maybe(Number)
}

enum SortDirection {
  Asc
  Desc
}

store Games {
  const GAMEINFOS_PATH = @asset(../assets/gameinfos.json)

  state data : Array(Game) = []

  fun parseVote (str : String) {
    if String.contains(str, "K") {
      String.replace(str, "K", "")
      |> Number.fromString
      |> Maybe.map((val : Number) { val * 1000 })
    } else if String.contains(str, "M") {
      String.replace(str, "M", "")
      |> Number.fromString
      |> Maybe.map((val : Number) { val * 1000000 })
    } else {
      Number.fromString(str)
    }
  }

  fun load : Promise(Void) {
    let response =
      await GAMEINFOS_PATH
      |> Http.get()
      |> Http.send()

    let data =
      response
      |> Result.map((r : Http.Response) { r.bodyString })
      |> Result.withDefault("")
      |> Json.parse
      |> Result.map((json : Object) { Result.withDefault(decode json as Array(Game), []) })
      |> Result.withDefault([])
      |> Array.map(
        (g : Game) {
          { g |
            upvotenum: parseVote(g.upvote),
            downvotenum: parseVote(g.downvote)
          }
        })

    next { data: data }
  }
}

component SortableTableHeader {
  property label : String
  property sort : String
  property sortDir : SortDirection
  property onClick : Function(Promise(Void))

  fun render : Html {
    <th
      class="sortable"
      onClick={onClick}>

      <{ label }>

      if label == sort {
        <span class="sort-arrow">
          case sortDir {
            SortDirection::Asc => "▲"
            SortDirection::Desc => "▼"
          }
        </span>
      }

    </th>
  }
}

component Main {
  connect Games exposing { data }
  state search = ""
  state onlyDefold = false
  state hideTags = false
  state sort = "Name"
  state sortDir = SortDirection::Asc

  fun componentDidMount {
    Games.load()
  }

  fun setSort (col : String) {
    let sortDir =
      if sort == col {
        if sortDir == SortDirection::Asc {
          SortDirection::Desc
        } else {
          SortDirection::Asc
        }
      } else {
        SortDirection::Asc
      }

    next
      {
        sort: col,
        sortDir: sortDir
      }
  }

  fun compare (val1 : a, val2 : a) : Number {
    if val1 < val2 && sortDir == SortDirection::Asc {
      -1
    } else if val1 < val2 && sortDir == SortDirection::Desc {
      1
    } else if val1 > val2 && sortDir == SortDirection::Asc {
      1
    } else if val1 > val2 && sortDir == SortDirection::Desc {
      -1
    } else {
      0
    }
  }

  get filteredGames {
    Games.data
    |> Array.select(
      (g : Game) {
        let containsName =
          g.name
          |> String.toLowerCase
          |> String.contains(search)

        let containsAuthor =
          g.author
          |> String.toLowerCase
          |> String.contains(search)

        (containsName || containsAuthor) && (!onlyDefold || onlyDefold && g.defold)
      })
    |> Array.sort(
      (a : Game, b : Game) : Number {
        case sort {
          "Defold" => compare(b.defold, a.defold)
          "Name" => compare(a.name, b.name)
          "Author" => compare(a.author, b.author)
          "Upvotes" => compare(Maybe.withDefault(a.upvotenum, 0), Maybe.withDefault(b.upvotenum, 0))
          "Downvotes" => compare(Maybe.withDefault(a.downvotenum, 0), Maybe.withDefault(b.downvotenum, 0))
          => 0
        }
      })
    |> Array.mapWithIndex(
      (g : Game, i : Number) {
        {i, g}
      })
  }

  fun render : Html {
    <div::app>
      <h1>"Poki Games - Showing"</h1>

      <div id="options">
        <input
          id="search"
          placeholder="search name or author"
          onInput={
            (e : Html.Event) {
              next
                {
                  search:
                    Dom.getValue(e.target)
                    |> String.toLowerCase
                }
            }
          }/>

        <label>
          <input
            type="checkbox"
            checked={onlyDefold}
            onClick={() { next { onlyDefold: !onlyDefold } }}/>

          "Only show Defold games"
        </label>

        <label>
          <input
            type="checkbox"
            checked={hideTags}
            onClick={() { next { hideTags: !hideTags } }}/>

          "Hide Tags"
        </label>
      </div>

      <table>
        <tr>
          <th/>

          <SortableTableHeader
            label={"Defold"}
            sort={sort}
            sortDir={sortDir}
            onClick={() { setSort("Defold") }}/>

          <SortableTableHeader
            label={"Name"}
            sort={sort}
            sortDir={sortDir}
            onClick={() { setSort("Name") }}/>

          <SortableTableHeader
            label={"Author"}
            sort={sort}
            sortDir={sortDir}
            onClick={() { setSort("Author") }}/>

          <SortableTableHeader
            label={"Upvotes"}
            sort={sort}
            sortDir={sortDir}
            onClick={() { setSort("Upvotes") }}/>

          <SortableTableHeader
            label={"Downvotes"}
            sort={sort}
            sortDir={sortDir}
            onClick={() { setSort("Downvotes") }}/>

          if !hideTags {
            <th>"Tags"</th>
          }
        </tr>

        for item of filteredGames {
          let {index, game} =
            item

          <tr>
            <td>
              <{ Number.toString(index + 1) }>
            </td>

            <td>
              <input
                type="checkbox"
                checked={game.defold}
                onClick={Html.Event.preventDefault}/>
            </td>

            <td>
              <a
                href="https://poki.com{url}"
                target="_blank">

                <{ game.name }>

              </a>
            </td>

            <td>
              <{ game.author }>
            </td>

            <td>
              <{ game.upvote }>
            </td>

            <td>
              <{ game.downvote }>
            </td>

            if !hideTags {
              <td>
                <ul>
                  for tag of game.tags {
                    <li>
                      <{ tag }>
                    </li>
                  }
                </ul>
              </td>
            }
          </tr>
        }
      </table>
    </div>
  }

  style app {
    h1 {
      margin-top: 0;
    }

    th {
      white-space: nowrap;
      padding: 5px 5px 15px;
      text-align: left;
      position: sticky;
      top: 0;
      background: white;
      border-bottom: 1px solid black;
    }

    th.sortable {
      cursor: pointer;
    }

    .sort-arrow {
      font-size: 12px;
      margin-left: 4px;
      display: inline-block;
    }

    td {
      background: #f1f1f1;
      text-align: left;
      padding: 5px;
    }

    tr:hover td {
      background: #e9e9e9;
    }

    ul {
      padding: 0;
    }

    li {
      display: inline-block;
      margin: 5px;
      border: 1px solid #ccc;
      padding: 4px;
      border-radius: 4px;
    }

    #options {
      margin: 20px 0;
    }

    #options label {
      margin-left: 20px;
      white-space: nowrap;
    }

    #search {
      margin: 20px 0;
    }

    #search {
      width: 300px;
      padding: 8px;
      font-size: 20px;
    }
  }
}
