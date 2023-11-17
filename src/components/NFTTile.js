
import { BrowserRouter as Router, Link } from "react-router-dom";
import { GetIpfsUrlFromPinata } from "../utils";

function NFTTile(data) {
  const newTo = {
    pathname: "/nftPage/" + data.data.tokenId,
  };

  const IPFSUrl = GetIpfsUrlFromPinata(data.data.image);

  return (
    <Link to={newTo}>
      <div className=" ml-12 mt-5 mb-12 flex flex-col items-center rounded-lg w-48 md:w-72">
        <img
          src={IPFSUrl}
          alt=""
          className="w-72 h-80 rounded-lg object-cover"
          crossOrigin="anonymous"
        />
        <div className="text-white w-full p-2  to-transparent rounded-lg pt-5 -mt-20">
          <strong className="text-xl">
            {data.data.name ? (
              <div>
                <div className="bg-white mx-10 py-2 bg-opacity-80 text-black rounded-full">
                  Click to explore
                </div>
              </div>
            ) : null}
          </strong>
        </div>
      </div>
    </Link>
  );
}

export default NFTTile;
