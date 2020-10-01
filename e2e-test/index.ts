import 'mocha'
import chai, { expect } from 'chai';
import chaiHttp from 'chai-http';

chai.use(chaiHttp);

const baseUrl = process.env["BACKEND_BASE_URL"] || "http://localhost:3000";

describe('GET /', () => {
    it('should return Hello World!', () => {
        return chai.request(baseUrl).get("/").
        then(res => {
            expect(res).to.have.status(200)
            expect(res).to.be.text;
            expect(res.text).to.equal("Hello World!")
        })
    });
});