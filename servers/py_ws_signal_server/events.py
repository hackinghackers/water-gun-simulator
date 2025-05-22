from dataclasses import dataclass, field
from dataclasses_json import dataclass_json, DataClassJsonMixin
import time


def current_millis() -> int:
    return int(time.time() * 1_000)

@dataclass_json
@dataclass
class SignalEvent(DataClassJsonMixin):
    event_name: str
    from_pid: int
    to_pid: int
    room_code: str
    generated_t: int = field(default_factory=current_millis, init=False)


@dataclass_json
@dataclass
class JoinRequest(SignalEvent):
    # fixed fields for a join request
    event_name: str = field(default="join", init=False)
    from_pid: int = field(default=-1, init=False)
    to_pid: int = field(default=-1, init=False) # init false because it come from the client

@dataclass_json
@dataclass
class JoinResponse(SignalEvent):
    event_name: str = field(default="join_response", init=False)

@dataclass_json
@dataclass
class PeerJoined(SignalEvent):
    joined_pid : int 
    event_name: str = field(default="peer_joined", init=False)

@dataclass_json
@dataclass
class SdpEvent(SignalEvent):
    sdp_type: str
    sdp_content: str
    event_name: str = field(default="sdp", init=False)
    # requires: from_pid, to_pid, room_code, sdp_type, sdp_content

@dataclass_json
@dataclass
class IceEvent(SignalEvent):
    ice_media: str
    ice_index: int
    ice_name: str
    event_name: str = field(default="ice", init=False)
    # requires: from_pid, to_pid, room_code, ice_media, ice_index, ice_name
