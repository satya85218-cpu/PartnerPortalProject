import { LightningElement, wire } from "lwc";
import getPartnerDeals from "@salesforce/apex/PartnerDealController.getPartnerDeals";

const COLUMNS = [
  {
    label: "Deal Name",
    fieldName: "recordUrl",
    type: "url",
    typeAttributes: {
      label: {
        fieldName: "Name"
      },
      target: "_self"
    }
  },
  {
    label: "Status",
    fieldName: "Status__c"
  },
  {
    label: "Approval Status",
    fieldName: "Approval_Status__c"
  },
  {
    label: "Deal Amount",
    fieldName: "Deal_Amount__c",
    type: "currency",
    sortable: true
  },
  {
    label: "Submitted Date",
    fieldName: "Submitted_Date__c",
    type: "date"
  },
  {
    label: "Customer",
    fieldName: "customerName"
  }
];

export default class PartnerDealList extends LightningElement {
  deals = [];
  filteredDeals = [];

  error;
  isLoading = true;

  sortedBy;
  sortDirection = "asc";

  searchKey = "";
  selectedStatus = "All";

  columns = COLUMNS;

  statusOptions = [
    { label: "All", value: "All" },
    { label: "Submitted", value: "Submitted" },
    { label: "Under Review", value: "Under Review" },
    { label: "Approved", value: "Approved" },
    { label: "Rejected", value: "Rejected" }
  ];

  @wire(getPartnerDeals)
  wiredDeals({ data, error }) {
    this.isLoading = false;

    if (data) {
      this.deals = data.map((deal) => ({
        ...deal,
        recordUrl: "partner-deal?id=" + deal.Id,
        customerName: deal.Customer_Account__r
          ? deal.Customer_Account__r.Name
          : ""
      }));

      this.filteredDeals = this.deals;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.deals = [];
      this.filteredDeals = [];
    }
  }

  handleSearch(event) {
    this.searchKey = event.target.value.toLowerCase();

    this.applyFilters();
  }

  handleStatusChange(event) {
    this.selectedStatus = event.detail.value;

    this.applyFilters();
  }

  handleSort(event) {
    this.sortedBy = event.detail.fieldName;
    this.sortDirection = event.detail.sortDirection;

    const data = [...this.filteredDeals];

    data.sort((a, b) => {
      let valueA = a[this.sortedBy] ?? "";
      let valueB = b[this.sortedBy] ?? "";

      if (typeof valueA === "string") {
        valueA = valueA.toLowerCase();
        valueB = valueB.toLowerCase();
      }

      let result = 0;

      if (valueA > valueB) {
        result = 1;
      } else if (valueA < valueB) {
        result = -1;
      }

      return this.sortDirection === "asc" ? result : -result;
    });

    this.filteredDeals = data;
  }

  applyFilters() {
    this.filteredDeals = this.deals.filter((deal) => {
      const matchesSearch =
        !this.searchKey ||
        (deal.Name && deal.Name.toLowerCase().includes(this.searchKey));

      const matchesStatus =
        this.selectedStatus === "All" || deal.Status__c === this.selectedStatus;

      return matchesSearch && matchesStatus;
    });
  }
}
