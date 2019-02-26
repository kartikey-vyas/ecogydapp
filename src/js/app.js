App = {
  web3Provider: null,
  contracts: {},
  lastRender: 0,
  lastProject: 0,

  init: async () => {
    console.log("Loading Dapp...");
    await App.initWeb3();
    await App.initContract();
    await App.initUI();
  },

  // https://medium.com/metamask/https-medium-com-metamask-breaking-change-injecting-web3-7722797916a8
  initWeb3: async () => {
    if (typeof web3 !== "undefined") {
      App.web3Provider = web3.currentProvider;
      web3 = new Web3(web3.currentProvider);
      console.log("Connected to MetaMask");
    } else {
      window.alert("Please connect to MetaMask.");
    }
    // Modern dapp browsers...
    if (window.ethereum) {
      window.web3 = new Web3(ethereum);
      try {
        // Request account access if needed
        await ethereum.enable();
        // Acccounts now exposed
        web3.eth.sendTransaction({
          /* ... */
        });
      } catch (error) {
        // User denied account access...
      }
    }
    // Legacy dapp browsers...
    else if (window.web3) {
      App.web3Provider = web3.currentProvider;
      window.web3 = new Web3(web3.currentProvider);
      // Acccounts always exposed
      web3.eth.sendTransaction({
        /* ... */
      });
    }
    // Non-dapp browsers...
    else {
      console.log(
        "Non-Ethereum browser detected. You should consider trying MetaMask!"
      );
    }
  },

  // load the contract
  initContract: async () => {
    const ecogyArtifact = await $.getJSON("Ecogy.json");
    App.contracts.Ecogy = TruffleContract(ecogyArtifact);
    App.contracts.Ecogy.setProvider(App.web3Provider);

    App.ecogy = await App.contracts.Ecogy.deployed();
    console.log("Ecogy smart contract has been loaded");
  },

  // intialise web elements from data stored in contract
  initUI: async () => {
    let pL = await App.ecogy.getProjectList.call();
    let projectList = pL.map(function (id) {
      return id.toNumber();
    });
    // assign references to HTML elements
    const projectContainer = $("#project-container");
    const projectTemplate = $("#project-template");
    // get data from each project and copy it into the webpage
    for (let i = App.lastProject; i < projectList.length; i++) {
      let a = await App.ecogy.projectMap(i);
      let b = await a;
      if (b[1]) {
        let project = await App.ecogy.getProject(projectList[i]);
        App.renderProjects(
          projectTemplate,
          projectContainer,
          project,
          projectList[i]
        );
        App.lastProject = i;
      } else {
        console.log(`project ${b[0]} has been deleted`);
      }
    }
    console.log("Projects retrieved");
    return App.bindEvents();
  },

  // handle button clicks
  bindEvents: async () => {
    $(document).on("click", ".btn-invest", App.handleInvest);
    $(document).on("click", ".btn-create", App.handleCreate);
    $(document).on("click", ".btn-delete", App.handleDelete);
    $(document).on("click", ".btn-info", App.renderInvestor);
  },

  // implement invest function upon button click
  handleInvest: async event => {
    event.preventDefault();

    // initialise required params
    let id = parseInt($(event.target).data("id"));
    let userAccount = web3.eth.accounts[0];
    let project = await App.ecogy.projectMap(id);
    let numShares = $("#" + id)
      .find(".form-control")
      .val();
    let cost = project[2] * numShares;

    // call solidity function
    await App.ecogy.invest(id, numShares, {
      from: userAccount,
      value: cost
    });
    App.updateUI(id);
  },

  // implement create function upon button click
  handleCreate: async event => {
    event.preventDefault();

    // initialise required params
    let projectId = $("#project-id").val();
    let price = $("#project-price").val() * 10 ** 18; // convert ether to wei

    await App.ecogy.createProject(projectId, price);
    App.updateUI(projectId);
    $("#createModal").modal("hide");
  },

  handleDelete: async event => {
    event.preventDefault();
    const projectId = $("#project-id-delete").val();
    await App.ecogy.deleteProject(projectId);
    window.location.reload();
  },

  // refresh UI elements that were modified by transaction
  updateUI: async id => {
    // initialise contract and project variables
    let project = await App.ecogy.getProject(id);
    const investEvent = App.ecogy.InvestmentMade({
      fromBlock: 0,
      toBlock: 'latest'
    });

    // listen for InvestmentMade() which is emitted after an invest() transaction is completed
    investEvent.watch(function (err, res) {
      // update only those fields which are changed by the transaction
      $("#" + id)
        .find(".form-control")
        .val("");
      $("#" + id)
        .find(".available-shares")
        .text(project[5]);
      $("#" + id)
        .find(".investors")
        .empty();
      for (var j = 0; j < project[3].length; j++) {
        $("#" + id)
          .find(".investors")
          .append(
            "<li>" + project[3][j] + " (" + project[4][j] + " shares)</li>"
          );
      }
    });

    let latestBlock = await web3.eth.getBlockNumber();
    const createEvent = App.ecogy.ProjectCreated({
      fromBlock: latestBlock
    });
    // listen for ProjectCreated() which is emitted after a createProject() transaction is completed
    createEvent.watch(function (err, res) {
      console.log(res);
      // reference requried web elements and generate new project row
      var newProject = $("#project-template");
      App.renderProjects(
        newProject,
        $("#projectContainer"),
        project,
        id
      );
    });
  },

  // generate projects on webpage
  renderProjects: function (template, container, project, id) {
    template.find(".panel-title").text(`PROJECT ${id}`);
    // price
    template
      .find(".project-price")
      .text(web3.utils.fromWei(project[2].toString()));
    // available shares
    template.find(".available-shares").text(project[5]);
    // assign data-id to invest button
    template.find(".btn-invest").attr("data-id", id);
    // investor list
    template.find(".investors").empty();
    for (var j = 0; j < project[3].length; j++) {
      template
        .find(".investors")
        .append(
          "<li>" + project[3][j] + " (" + project[4][j] + " shares)</li>"
        );
    }
    // assign project id to html tag
    template.find(".project-row").attr("id", id);
    // add project to web container
    container.append(template.html());

    // ensure template has a unique, inaccessible id
    template.find(".project-row").attr("id", "freebobby");
  },

  renderInvestor: async id => {
    let investor = await App.ecogy.getInvestor();
    for (let i = App.lastRender; i < investor[1].length; i++) {
      let newInvestment = $("#investment-template").clone();
      let project = investor[1][i].toNumber();
      let shares = investor[2][i].toNumber();
      let price = await App.ecogy.projectMap(project);
      let value = web3.utils.fromWei(price[2].toString()) * shares;
      newInvestment.find(".project-id").text(`Project ${project}:`);
      newInvestment.find(".project-holdings").text(`${shares} Shares (${value} ETH)`);
      newInvestment.find(".btn-sell").attr("id", project);
      $("#current-investments").append(newInvestment.html());
      App.lastRender = i + 1;
    }
  }

};

$(function () {
  $(window).on("load", function () {
    App.init();
  });
});