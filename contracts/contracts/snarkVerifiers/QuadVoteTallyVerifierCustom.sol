// SPDX-License-Identifier: MIT

// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.6.12;

library Pairing {

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero. 
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {

        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {

        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"pairing-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {

        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }

    /* @return The result of computing the pairing check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {

        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];

        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"pairing-opcode-failed");

        return out[0] != 0;
    }
}

contract QuadVoteTallyVerifierCustom {

    using Pairing for *;

    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKey {
        Pairing.G1Point alpha1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[11] IC;
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alpha1 = Pairing.G1Point(uint256(293089235867224699536482180938394230067962199851011216067376566083334277172),uint256(13086134622934158593450033649616058486061020062189779629632805853293713425336));
        vk.beta2 = Pairing.G2Point([uint256(6114741828566539306031727483813639944357413571881975320008024491209084841656),uint256(20770326479742698604639008021797738470591426184324417755400165404614184616472)], [uint256(12897160845824549494749400152225761728356531432016848542412131330045849637866),uint256(19445655216993897563908055359581807222809758373277675683773253725841573068535)]);
        vk.gamma2 = Pairing.G2Point([uint256(7691758787506249422762032096315387929217677235193788182999431741143109956998),uint256(20339600474477910992590236432201291588389495803965469223888493644110904262604)], [uint256(8452122516294944815603379954539367684468813587597578788685334018141390638342),uint256(21733314419883256795784171116131036710283056784755135965233974509851301461448)]);
        vk.delta2 = Pairing.G2Point([uint256(19331426541686400479497372876521631209920596968143329835238258273460966054300),uint256(16956429691965767383686056263196400205390273213864746066359358450999333339703)], [uint256(20364297373933603184466590797261651908615097075077602506363717982877453629025),uint256(14401403016841240783158044611179494310507572317502168222677110216540759094595)]);
        vk.IC[0] = Pairing.G1Point(uint256(16847187102052526334551268369286504731626812906261149680308409672948178707258),uint256(12217128308619171556238679196644902746624342249833336240174443790189407023663));
        vk.IC[1] = Pairing.G1Point(uint256(14345815754559251738502100703437993838196057023369130571176365850134036755594),uint256(272771157805588047097572130554011041230273660526450536789825971339470643037));
        vk.IC[2] = Pairing.G1Point(uint256(6111115547273346475969307987520928952136245508156133078151859071606655099194),uint256(14927169718953544698729033887570351748855745139121747328696310981230836214833));
        vk.IC[3] = Pairing.G1Point(uint256(20478803628032006749281550746598304717130642263072307832868894350348206456362),uint256(13038696267478649475000250279497204957096439817515594699596588545373104953734));
        vk.IC[4] = Pairing.G1Point(uint256(4324839803867906919094905107422644644653719235148094844111550224227600513633),uint256(18373309156045387753722245799372295263970748592253723847308991964526052747839));
        vk.IC[5] = Pairing.G1Point(uint256(18753577623910438691175528873337623348490877900779622682253075529765723762591),uint256(9843716481722697430150421148241197623056010859861557078063370632061378570789));
        vk.IC[6] = Pairing.G1Point(uint256(13991047778588019497888130171362792200084117102294225558827098236573751159075),uint256(4755524455138330648750690070168368148884997823666907243579834645510716955447));
        vk.IC[7] = Pairing.G1Point(uint256(13781091497514442071177093453213977566490570316772268651984379227936193430455),uint256(18161923363791002871879524121057520573663455022082235441106147251640688811165));
        vk.IC[8] = Pairing.G1Point(uint256(496264935626465625447401185532381476212580297348027413711874523068270350340),uint256(13911895118675906316113224836198986878937675534110051381398720815549460576134));
        vk.IC[9] = Pairing.G1Point(uint256(19713515534509233461360927338842733004255245090850974287386932201997119417782),uint256(3012766173531612086065790577641797776402189820192282970783489363867037133230));
        vk.IC[10] = Pairing.G1Point(uint256(10269743509645585154331358679989746559906852247996875425498176293161505988865),uint256(7063997932013617513526721175245448532375345634711511010626792775099463645172));

    }
    
    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory input
    ) public view returns (bool) {

        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);

        VerifyingKey memory vk = verifyingKey();

        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        //for (uint256 i = 0; i < input.length; i++) {
        for (uint256 i = 0; i < 10; i++) {
            require(input[i] < SNARK_SCALAR_FIELD,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.plus(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }

        vk_x = Pairing.plus(vk_x, vk.IC[0]);

        return Pairing.pairing(
            Pairing.negate(proof.A),
            proof.B,
            vk.alpha1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.C,
            vk.delta2
        );
    }
}
