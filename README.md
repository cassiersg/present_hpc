# Masked PRESENT harwdare implementation using the HPC masking scheme

Implementation of the PRESENT block cipher (encryption only) with 128-bit key
using the HPC masking scheme.

This implementation depends on the
[fullVerif](https://github.com/cassiersg/fullverif) [gadget library](https://github.com/cassiersg/fullverif/tree/be5771390221df5af7843ad1dcacb2d70705d8dd/lib_v)
and passes fullVerif security checks.
See [here](https://github.com/cassiersg/fullverif#usage) for running the fullVerif tool on this implementation.

HPC1/HPC2 gadget selection is done through a `define` in the `present_sbox_rnd.vh` file, and making order `d` is a parameter of the `MSKpresent_encrypt` top-level module.


THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
