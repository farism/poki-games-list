<script lang="ts">
  import data from "$lib/gameinfos.json";
  import lodash from "lodash";

  function parseVotes(val: string) {
    if (val.includes("K")) {
      return parseFloat(val.replace("K", "")) * 1_000;
    } else if (val.includes("M")) {
      return parseFloat(val.replace("M", "")) * 1_000_000;
    }

    return parseFloat(val);
  }

  const dataWithNumericVotes = data.map((g) => {
    const upvotes = parseVotes(g.upvote);
    const downvotes = parseVotes(g.downvote);
    const g2 = g as any;
    g2.upvotes = upvotes;
    g2.downvotes = downvotes;

    return g;
  });

  $: onlyDefold = false;

  $: hideTags = false;

  $: sort = "name";

  $: sortDir = "asc" as "asc" | "desc";

  $: search = "";

  $: sorted = lodash.orderBy(dataWithNumericVotes, [sort], [sortDir]);

  $: searched = (
    search
      ? sorted.filter(
          (g) =>
            g.name.toLowerCase().includes(search.toLowerCase()) ||
            g.author.toLowerCase().includes(search.toLowerCase())
        )
      : sorted
  ).filter((g) => (onlyDefold ? g.defold : true));

  function sortBy(field: string) {
    if (sort === field) {
      sortDir = sortDir == "asc" ? "desc" : "asc";
    }
    sort = field;
  }
</script>

<h1>Poki Games - Showing {searched.length} of {data.length}</h1>

<div id="options">
  <input id="search" placeholder="search name or author" bind:value={search} />
  <label>
    <input type="checkbox" bind:checked={onlyDefold} />
    Only show Defold games
  </label>
  <label>
    <input type="checkbox" bind:checked={hideTags} />
    Hide Tags
  </label>
</div>

<table>
  <tr>
    <th>#</th>
    <th on:click={() => sortBy("defold")}>
      Defold{#if sort == "defold"}<span class="sort">{#if sortDir == "asc"}▲{:else}▼{/if}</span>{/if}
    </th>
    <th on:click={() => sortBy("name")}>
      Name{#if sort == "name"}<span class="sort">{#if sortDir == "asc"}▲{:else}▼{/if}</span>{/if}
    </th>
    <th on:click={() => sortBy("author")}>
      Author{#if sort == "author"}<span class="sort">{#if sortDir == "asc"}▲{:else}▼{/if}</span>{/if}
    </th>
    <th on:click={() => sortBy("upvotes")}>
      Upvotes{#if sort == "upvotes"}<span class="sort">{#if sortDir == "asc"}▲{:else}▼{/if}</span>{/if}
    </th>
    <th on:click={() => sortBy("downvotes")}>
      Downvotes{#if sort == "downvotes"}<span class="sort">{#if sortDir == "asc"}▲{:else}▼{/if}</span>{/if}
    </th>
    {#if !hideTags}
      <th width="100%">Tags</th>
    {/if}
  </tr>
  {#each searched as { author, defold, downvote, name, tags, upvote, url }, i (url)}
    <tr>
      <td>{i + 1}</td>
      <td>
        <input type="checkbox" checked={defold} onclick="return false" />
      </td>
      <td>
        <a href="https://poki.com{url}" target="_blank">{name}</a>
      </td>
      <td>{author}</td>
      <td>{upvote}</td>
      <td>{downvote}</td>
      {#if !hideTags}
        <td>
          <ul>
            {#each tags as tag}<li>{tag}</li>{/each}
          </ul>
        </td>
      {/if}
    </tr>
  {/each}
</table>

<style>
  :global(body) {
    padding: 20px;
  }

  h1 {
    margin-top: 0;
  }

  th {
    white-space: nowrap;
  }

  th,
  td {
    text-align: left;
    padding: 5px;
  }

  td {
    background: #f1f1f1;
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
  }

  #search {
    margin: 20px 0;
  }

  #search {
    width: 300px;
    padding: 8px;
    font-size: 20px;
  }

  .sort {
    font-size: 12px;
    margin-left: 4px;
    display: inline-block;
  }
</style>
