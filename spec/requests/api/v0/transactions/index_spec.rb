# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V0::Transactions", type: :request do
  let(:headers)  { { "Content-Type" => "application/json" } }
  let(:user)     { create(:user) }
  let(:currency) { create(:currency) }
  let(:account)  { create(:account, user: user, currency: currency) }
  let(:category) { create(:category, user: user) }

  describe "GET /api/v0/transactions" do
    let(:endpoint)        { "/api/v0/transactions" }
    let(:request_headers) { headers }
    let(:request_params)  { {} }

    before do
      get endpoint, params: request_params, headers: request_headers
    end

    # SUCCESS PATHS
    context "when authenticated with no filters" do
      let(:request_headers) { headers.merge(auth_headers(user)) }

      before do
        create(:transaction, user: user, account: account, currency: currency, category: category,
               title: "Groceries", transaction_date: 2.days.ago)
        create(:transaction, user: user, account: account, currency: currency, category: category,
               title: "Rent", transaction_date: 1.day.ago)
      end

      it "returns 200 and matches schema" do
        get endpoint, params: request_params, headers: request_headers
        expect(response).to have_http_status(:ok)
        expect(response).to match_json_schema("transactions/index_response")
      end

      it "returns only the current user's transactions" do
        other_user = create(:user)
        create(:transaction, user: other_user, account: create(:account, user: other_user, currency: currency), currency: currency)
        get endpoint, params: request_params, headers: request_headers
        ids = JSON.parse(response.body)["transactions"].map { |t| t["user_id"] }.uniq
        expect(ids).to eq([user.id])
      end
    end

    context "when filtered by account_id" do
      let(:other_account)   { create(:account, user: user, currency: currency) }
      let(:request_headers) { headers.merge(auth_headers(user)) }
      let(:request_params)  { { account_id: account.id } }

      before do
        create(:transaction, user: user, account: account, currency: currency)
        create(:transaction, user: user, account: other_account, currency: currency)
      end

      it "returns only transactions for that account" do
        get endpoint, params: request_params, headers: request_headers
        expect(response).to have_http_status(:ok)
        account_ids = JSON.parse(response.body)["transactions"].map { |t| t["account_id"] }.uniq
        expect(account_ids).to eq([account.id])
      end
    end

    context "when filtered by category_id" do
      let(:other_category)  { create(:category, user: user) }
      let(:request_headers) { headers.merge(auth_headers(user)) }
      let(:request_params)  { { category_id: category.id } }

      before do
        create(:transaction, user: user, account: account, currency: currency, category: category)
        create(:transaction, user: user, account: account, currency: currency, category: other_category)
      end

      it "returns only transactions for that category" do
        get endpoint, params: request_params, headers: request_headers
        expect(response).to have_http_status(:ok)
        category_ids = JSON.parse(response.body)["transactions"].map { |t| t["category_id"] }.uniq
        expect(category_ids).to eq([category.id])
      end
    end

    context "when filtered by date range" do
      let(:request_headers) { headers.merge(auth_headers(user)) }
      let(:request_params)  { { date_from: 3.days.ago.iso8601, date_to: 1.day.ago.iso8601 } }

      before do
        create(:transaction, user: user, account: account, currency: currency,
               title: "Old",   transaction_date: 5.days.ago)
        create(:transaction, user: user, account: account, currency: currency,
               title: "InRange", transaction_date: 2.days.ago)
        create(:transaction, user: user, account: account, currency: currency,
               title: "Future", transaction_date: Time.current)
      end

      it "returns only transactions within the date range" do
        get endpoint, params: request_params, headers: request_headers
        expect(response).to have_http_status(:ok)
        titles = JSON.parse(response.body)["transactions"].map { |t| t["title"] }
        expect(titles).to include("InRange")
        expect(titles).not_to include("Old", "Future")
      end
    end

    context "when filtered by search term matching title" do
      let(:request_headers) { headers.merge(auth_headers(user)) }
      let(:request_params)  { { search: "grocery" } }

      before do
        create(:transaction, user: user, account: account, currency: currency, title: "Weekly Grocery Run")
        create(:transaction, user: user, account: account, currency: currency, title: "Rent Payment")
      end

      it "returns transactions whose title matches case-insensitively" do
        get endpoint, params: request_params, headers: request_headers
        expect(response).to have_http_status(:ok)
        titles = JSON.parse(response.body)["transactions"].map { |t| t["title"] }
        expect(titles).to include("Weekly Grocery Run")
        expect(titles).not_to include("Rent Payment")
      end
    end

    context "when filtered by search term matching note" do
      let(:request_headers) { headers.merge(auth_headers(user)) }
      let(:request_params)  { { search: "monthly" } }

      before do
        create(:transaction, user: user, account: account, currency: currency,
               title: "Rent", note: "Monthly payment")
        create(:transaction, user: user, account: account, currency: currency,
               title: "Coffee", note: nil)
      end

      it "returns transactions whose note matches case-insensitively" do
        get endpoint, params: request_params, headers: request_headers
        expect(response).to have_http_status(:ok)
        titles = JSON.parse(response.body)["transactions"].map { |t| t["title"] }
        expect(titles).to include("Rent")
        expect(titles).not_to include("Coffee")
      end
    end

    # FAILURE PATHS
    context "when unauthenticated" do
      it "returns 401 and matches error schema" do
        expect(response).to have_http_status(:unauthorized)
        expect(response).to match_json_schema("error_response")
      end
    end

    context "when date_from is not a valid datetime" do
      let(:request_headers) { headers.merge(auth_headers(user)) }
      let(:request_params)  { { date_from: "not-a-date" } }

      it "returns 422 and matches error schema" do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to match_json_schema("error_response")
      end
    end

    context "when date_to is not a valid datetime" do
      let(:request_headers) { headers.merge(auth_headers(user)) }
      let(:request_params)  { { date_to: "bad-date" } }

      it "returns 422 and matches error schema" do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to match_json_schema("error_response")
      end
    end
  end
end
