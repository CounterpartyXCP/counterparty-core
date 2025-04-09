use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct ApiEndpoint {
    pub function: String,
    pub description: String,
    pub args: Vec<ApiEndpointArg>,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct ApiEndpointArg {
    pub name: String,
    #[serde(default)]
    pub required: bool,
    #[serde(rename = "type")]
    pub arg_type: String,
    #[serde(default)]
    pub description: Option<String>,
    #[serde(default)]
    pub default: Option<serde_json::Value>,
    #[serde(default)]
    pub members: Option<Vec<serde_json::Value>>,
}
